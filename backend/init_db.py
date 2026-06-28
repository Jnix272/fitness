import duckdb

def init_db():
    conn = duckdb.connect('workouts.duckdb')

    # Create Core Tables
    conn.execute("""
    CREATE TABLE IF NOT EXISTS exercises (
        exercise_id INTEGER PRIMARY KEY,
        name TEXT,
        category TEXT,
        primary_muscle_group TEXT
    );
    """)

    conn.execute("""
    CREATE SEQUENCE IF NOT EXISTS session_id_seq;
    CREATE TABLE IF NOT EXISTS workout_sessions (
        session_id INTEGER PRIMARY KEY DEFAULT nextval('session_id_seq'),
        session_date DATE,
        template TEXT,
        notes TEXT
    );
    """)

    conn.execute("""
    CREATE TABLE IF NOT EXISTS warmup_cooldown_protocols (
        id INTEGER PRIMARY KEY,
        protocol_type TEXT,
        phase TEXT,
        duration_min TEXT,
        session_tags TEXT,
        steps TEXT
    );
    """)

    conn.execute("""
    CREATE TABLE IF NOT EXISTS user_settings (
        id INTEGER PRIMARY KEY,
        primary_goal TEXT,
        preferred_frequency INTEGER,
        equipment_constraints TEXT
    );
    """)

    conn.execute("""
    CREATE SEQUENCE IF NOT EXISTS set_id_seq;
    CREATE TABLE IF NOT EXISTS session_sets (
        set_id INTEGER PRIMARY KEY DEFAULT nextval('set_id_seq'),
        session_id INTEGER REFERENCES workout_sessions(session_id),
        exercise_id INTEGER REFERENCES exercises(exercise_id),
        set_number INTEGER,
        reps_completed INTEGER,
        weight_kg REAL,
        rir INTEGER,
        rpe INTEGER
    );
    """)

    # Clear existing exercises if re-running
    conn.execute("DELETE FROM exercises;")

    # Seed Full Body A & B catalog
    exercises_data = [
        (1, 'Squat (goblet)', 'squat', 'quads'),
        (2, 'Push-up', 'push', 'chest'),
        (3, 'Hip thrust', 'hinge', 'glutes'),
        (4, 'Horizontal row', 'pull', 'back'),
        (5, 'Calf raise', 'squat', 'calves'),
        (6, 'Plank', 'core', 'core'),
        (7, 'Bulgarian split squat', 'squat', 'quads'),
        (8, 'Romanian deadlift', 'hinge', 'hamstrings'),
        (9, 'Overhead push', 'push', 'shoulders'),
        (10, 'Single-leg glute bridge', 'hinge', 'glutes'),
        (11, 'Side plank', 'core', 'core'),
        # Warm-up / Cool-down placeholders
        (12, 'Dynamic full-body', 'warm-up', 'full_body'),
        (13, 'Lower-body static', 'cool-down', 'lower_body'),
        (14, 'Recovery walk', 'cool-down', 'full_body')
    ]
    
    conn.executemany("INSERT INTO exercises VALUES (?, ?, ?, ?)", exercises_data)
    
    # Seed Protocols
    conn.execute("DELETE FROM warmup_cooldown_protocols;")
    protocols_data = [
        (1, 'Dynamic full-body', 'warm-up', '7-10 min', 'FullBodyA,FullBodyB', '1. March in place\n2. Arm circles\n3. Leg swings\n4. Bodyweight squat\n5. Hip circles'),
        (2, 'Lower-body static', 'cool-down', '8-10 min', 'FullBodyA', '1. Standing quad stretch\n2. Kneeling hip flexor\n3. Seated hamstring\n4. Figure-four glute'),
        (3, 'Upper-body static', 'cool-down', '8-10 min', 'FullBodyB', '1. Cross-body shoulder\n2. Tricep overhead\n3. Lunge with spinal twist\n4. Childs pose')
    ]
    conn.executemany("INSERT INTO warmup_cooldown_protocols VALUES (?, ?, ?, ?, ?, ?)", protocols_data)
    
    # Seed User Settings
    conn.execute("DELETE FROM user_settings;")
    conn.execute("INSERT INTO user_settings VALUES (1, 'muscle_gain', 3, 'minimal');")
    
    print("Database initialized and seeded.")
    conn.close()

if __name__ == '__main__':
    init_db()
