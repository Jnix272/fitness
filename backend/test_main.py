from fastapi.testclient import TestClient
from main import app, get_db
import pytest
import os
import duckdb

client = TestClient(app)

# Use an in-memory DB for tests, or a test DB file.
# For simplicity, we'll patch the DB_PATH or just use the same file since it's local dev,
# but using a test db is better. We'll monkeypatch DB_PATH.

@pytest.fixture(autouse=True)
def setup_db(monkeypatch):
    test_db = 'test_workouts.duckdb'
    monkeypatch.setattr('main.DB_PATH', test_db)
    
    conn = duckdb.connect(test_db)
    conn.execute("""
    CREATE TABLE exercises (
        exercise_id INTEGER PRIMARY KEY,
        name TEXT,
        category TEXT,
        primary_muscle_group TEXT
    );
    CREATE SEQUENCE IF NOT EXISTS session_id_seq;
    CREATE TABLE workout_sessions (
        session_id INTEGER PRIMARY KEY DEFAULT nextval('session_id_seq'),
        session_date DATE,
        template TEXT,
        notes TEXT
    );
    CREATE SEQUENCE IF NOT EXISTS set_id_seq;
    CREATE TABLE session_sets (
        set_id INTEGER PRIMARY KEY DEFAULT nextval('set_id_seq'),
        session_id INTEGER REFERENCES workout_sessions(session_id),
        exercise_id INTEGER REFERENCES exercises(exercise_id),
        set_number INTEGER,
        reps_completed INTEGER,
        weight_kg REAL,
        rir INTEGER,
        rpe INTEGER
    );
    CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY,
        primary_goal TEXT,
        preferred_frequency INTEGER,
        equipment_constraints TEXT
    );
    """)
    conn.execute("INSERT INTO exercises VALUES (1, 'Squat', 'squat', 'quads');")
    conn.execute("INSERT INTO user_settings VALUES (1, 'muscle_gain', 3, 'minimal');")
    conn.close()
    
    yield
    
    if os.path.exists(test_db):
        os.remove(test_db)


def test_log_session():
    response = client.post(
        "/sessions",
        json={
            "session_date": "2026-06-27",
            "template": "FullBodyA",
            "notes": "Felt good",
            "sets": [
                {
                    "exercise_id": 1,
                    "set_number": 1,
                    "reps_completed": 10,
                    "weight_kg": 20.0,
                    "rir": 2,
                    "rpe": 8
                }
            ]
        }
    )
    assert response.status_code == 201, response.text
    assert response.json()["status"] == "success"

def test_analytics_and_suggestions():
    # Insert session
    client.post(
        "/sessions",
        json={
            "session_date": "2026-06-27",
            "template": "FullBodyA",
            "sets": [
                {
                    "exercise_id": 1,
                    "set_number": 1,
                    "reps_completed": 10,
                    "weight_kg": 20.0,
                    "rir": 2,  # RIR <= 3 -> hard set
                    "rpe": 8
                }
            ]
        }
    )
    
    response = client.get("/analytics/weekly")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["primary_muscle_group"] == "quads"
    assert data[0]["hard_sets"] == 1
    assert data[0]["volume_load"] == 200.0  # 10 * 20.0
    
    sugg_response = client.get("/suggestions/next")
    assert sugg_response.status_code == 200
    sugg_data = sugg_response.json()
    # It should recommend FullBodyB since last was FullBodyA
    assert sugg_data["recommended_template"] == "FullBodyB"
