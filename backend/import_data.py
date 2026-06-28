import duckdb
import csv
from datetime import datetime

DB_PATH = 'workouts.duckdb'

def import_csv(file_path: str):
    conn = duckdb.connect(DB_PATH)
    try:
        with open(file_path, mode='r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                session_date = row['date']
                template = row['template']
                exercise_name = row['exercise']
                
                # Fetch exercise_id
                ex_row = conn.execute("SELECT exercise_id FROM exercises WHERE name = ?", (exercise_name,)).fetchone()
                if not ex_row:
                    continue
                exercise_id = ex_row[0]
                
                # Get or create session
                sess_row = conn.execute("SELECT session_id FROM workout_sessions WHERE session_date = ?", (session_date,)).fetchone()
                if sess_row:
                    session_id = sess_row[0]
                else:
                    session_id = conn.execute(
                        "INSERT INTO workout_sessions (session_date, template) VALUES (?, ?) RETURNING session_id", 
                        (session_date, template)
                    ).fetchone()[0]
                
                # Insert set
                conn.execute(
                    """INSERT INTO session_sets (session_id, exercise_id, set_number, reps_completed, weight_kg, rir, rpe) 
                    VALUES (?, ?, ?, ?, ?, ?, ?)""",
                    (session_id, exercise_id, int(row['set_number']), int(row['reps']), float(row['weight']), int(row['rir']), int(row['rpe']))
                )
        print("Import successful.")
    finally:
        conn.close()

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        import_csv(sys.argv[1])
    else:
        print("Usage: python import_data.py <path_to_csv>")
