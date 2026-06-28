from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import date, datetime, timedelta
import duckdb

app = FastAPI(title="Personal Workout Coach API")

DB_PATH = 'workouts.duckdb'

# Pydantic Models
class SetInput(BaseModel):
    exercise_id: int
    set_number: int
    reps_completed: int
    weight_kg: float
    rir: int
    rpe: int

class SessionInput(BaseModel):
    session_date: date
    template: str
    notes: Optional[str] = None
    sets: List[SetInput]

class MuscleGroupAnalytics(BaseModel):
    primary_muscle_group: str
    hard_sets: int
    volume_load: float
    avg_rpe: float

class SuggestionResponse(BaseModel):
    suggestions: List[str]
    recommended_template: str
    summary: str

class Protocol(BaseModel):
    id: int
    protocol_type: str
    phase: str
    duration_min: str
    session_tags: str
    steps: str

def get_db():
    return duckdb.connect(DB_PATH)

@app.get("/protocols", response_model=List[Protocol])
def get_protocols(template: str):
    conn = get_db()
    try:
        # Simple LIKE query to match session_tags (e.g. 'FullBodyA' in 'FullBodyA,FullBodyB')
        query = "SELECT id, protocol_type, phase, duration_min, session_tags, steps FROM warmup_cooldown_protocols WHERE session_tags LIKE ?"
        results = conn.execute(query, (f'%{template}%',)).fetchall()
        
        protocols = []
        for row in results:
            protocols.append(Protocol(
                id=row[0],
                protocol_type=row[1],
                phase=row[2],
                duration_min=row[3],
                session_tags=row[4],
                steps=row[5]
            ))
        return protocols
    finally:
        conn.close()

@app.post("/sessions", status_code=201)
def log_session(session: SessionInput):
    conn = get_db()
    try:
        # Create session record
        result = conn.execute(
            "INSERT INTO workout_sessions (session_date, template, notes) VALUES (?, ?, ?) RETURNING session_id",
            (session.session_date, session.template, session.notes)
        ).fetchone()
        
        session_id = result[0]
        
        # Insert sets
        for s in session.sets:
            conn.execute(
                """INSERT INTO session_sets 
                (session_id, exercise_id, set_number, reps_completed, weight_kg, rir, rpe) 
                VALUES (?, ?, ?, ?, ?, ?, ?)""",
                (session_id, s.exercise_id, s.set_number, s.reps_completed, s.weight_kg, s.rir, s.rpe)
            )
        return {"status": "success", "session_id": session_id}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()

@app.get("/analytics/weekly", response_model=List[MuscleGroupAnalytics])
def get_weekly_analytics():
    conn = get_db()
    # hard_sets: rir <= 3 OR rpe >= 7
    # volume_load: reps * load
    query = """
        SELECT 
            e.primary_muscle_group,
            COUNT(CASE WHEN s.rir <= 3 OR s.rpe >= 7 THEN 1 END) as hard_sets,
            SUM(s.reps_completed * s.weight_kg) as volume_load,
            AVG(s.rpe) as avg_rpe
        FROM workout_sessions ws
        JOIN session_sets s ON ws.session_id = s.session_id
        JOIN exercises e ON s.exercise_id = e.exercise_id
        WHERE ws.session_date >= current_date() - INTERVAL 7 DAY
        GROUP BY e.primary_muscle_group
    """
    results = conn.execute(query).fetchall()
    conn.close()
    
    analytics = []
    for row in results:
        analytics.append(MuscleGroupAnalytics(
            primary_muscle_group=row[0],
            hard_sets=row[1],
            volume_load=row[2] or 0.0,
            avg_rpe=row[3] or 0.0
        ))
    return analytics

class UserSettings(BaseModel):
    primary_goal: str
    preferred_frequency: int
    equipment_constraints: str

@app.get("/settings", response_model=UserSettings)
def get_settings():
    conn = get_db()
    try:
        row = conn.execute("SELECT primary_goal, preferred_frequency, equipment_constraints FROM user_settings WHERE id = 1").fetchone()
        return UserSettings(
            primary_goal=row[0],
            preferred_frequency=row[1],
            equipment_constraints=row[2]
        )
    finally:
        conn.close()

@app.get("/suggestions/next", response_model=SuggestionResponse)
def get_next_suggestions():
    analytics = get_weekly_analytics()
    settings = get_settings()
    
    # Define volume landmarks based on goal
    if settings.primary_goal == 'muscle_gain':
        mev, mrv = 10, 20
    elif settings.primary_goal == 'strength':
        mev, mrv = 8, 15
    else: # endurance
        mev, mrv = 6, 10
        
    suggestions = []
    under_worked = []
    over_worked = []
    
    for stat in analytics:
        if stat.hard_sets < mev:
            under_worked.append(stat.primary_muscle_group)
            suggestions.append(f"Add sets for {stat.primary_muscle_group} (below MEV of {mev}).")
        elif stat.hard_sets > mrv:
            over_worked.append(stat.primary_muscle_group)
            suggestions.append(f"Reduce sets for {stat.primary_muscle_group} (above MRV of {mrv}).")
            
    conn = get_db()
    last_session = conn.execute("SELECT template FROM workout_sessions ORDER BY session_date DESC LIMIT 1").fetchone()
    conn.close()
    
    recommended_template = "FullBodyA"
    if last_session and last_session[0] == "FullBodyA":
        recommended_template = "FullBodyB"
    elif last_session and last_session[0] == "FullBodyB":
        recommended_template = "FullBodyA"
        
    summary = f"Training volume is on track for {settings.primary_goal}."
    if under_worked:
        summary = f"Volume is below MEV for: {', '.join(under_worked)}."
    elif over_worked:
        summary = f"High fatigue risk (above MRV) in: {', '.join(over_worked)}."
        
    return SuggestionResponse(
        suggestions=suggestions,
        recommended_template=recommended_template,
        summary=summary
    )

import httpx

class ExplainRequest(BaseModel):
    suggestion: str

@app.post("/coach/explain")
async def explain_suggestion(req: ExplainRequest):
    prompt = f"Explain briefly why a fitness coach would suggest this rule for strength training: {req.suggestion}. Keep it under 50 words."
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:11434/api/generate",
                json={"model": "llama3", "prompt": prompt, "stream": False},
                timeout=10.0
            )
        return {"explanation": response.json().get("response", "Could not generate explanation.")}
    except Exception as e:
        return {"explanation": f"LLM backend unavailable: {e}"}

class ChatRequest(BaseModel):
    message: str

@app.post("/coach/chat")
async def chat_coach(req: ChatRequest):
    prompt = f"You are a helpful fitness coach. The user asks: {req.message}. Answer concisely."
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://localhost:11434/api/generate",
                json={"model": "llama3", "prompt": prompt, "stream": False},
                timeout=10.0
            )
        return {"reply": response.json().get("response", "Could not generate reply.")}
    except Exception as e:
        return {"reply": f"LLM backend unavailable: {e}"}
