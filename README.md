# 🏋️ Personal Workout Coach App

A fully local, privacy-first personal fitness tracking and coaching application.  
Built with **Flutter** (frontend) + **FastAPI** + **DuckDB** (backend) + optional **Ollama** AI coaching.

---

## 📁 Project Structure

```
fitness/
├── backend/                  # Python FastAPI + DuckDB
│   ├── main.py               # API server (all endpoints)
│   ├── init_db.py            # Database schema + seed data
│   ├── import_data.py        # Import historic workout data from CSV
│   ├── test_main.py          # Pytest unit tests
│   └── workouts.duckdb       # Local DuckDB database file
│
├── frontend/                 # Flutter mobile/desktop app
│   ├── lib/
│   │   ├── main.dart         # All screens (Home, Log, Progress, Coach)
│   │   └── api_client.dart   # HTTP client for the FastAPI backend
│   └── test/
│       └── widget_test.dart  # Flutter widget tests
│
└── docs/                     # Additional documentation
```

---

## ✨ Features

| Feature | Description |
|---|---|
| 📋 **Workout Logging** | Log sessions with sets, reps, weight, RIR, and RPE |
| 🔥 **Warm-up / Cool-down** | Guided protocols before and after every session |
| 📊 **Progress Analytics** | Bar chart of weekly hard sets per muscle group |
| 🧠 **AI Coach** | Rule-based MEV/MRV suggestions driven by your goal |
| 💬 **LLM Chat** | Ask your local Ollama AI coach anything (optional) |
| 📥 **Data Import** | Import historic workout data from CSV |

---

## 🚀 Step-by-Step Setup Guide

### Prerequisites

Before you begin, make sure you have the following installed:

| Tool | Version | Download |
|---|---|---|
| Python | 3.10+ | https://www.python.org/downloads/ |
| Flutter | 3.0+ | https://docs.flutter.dev/get-started/install |
| Git | Any | https://git-scm.com/ |
| Ollama *(optional)* | Latest | https://ollama.com/ |

---

### Step 1 — Clone the Repository

```powershell
git clone <your-repo-url>
cd fitness
```

---

### Step 2 — Set Up the Backend

#### 2a. Create a Python virtual environment

```powershell
cd backend
python -m venv .venv
```

#### 2b. Activate the virtual environment

```powershell
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# Windows (CMD)
.venv\Scripts\activate.bat

# macOS / Linux
source .venv/bin/activate
```

> **Tip:** You'll see `(.venv)` at the start of your terminal prompt when active.

#### 2c. Install Python dependencies

```powershell
pip install fastapi[all] uvicorn duckdb pydantic pytest httpx
```

#### 2d. Initialize the database

This creates `workouts.duckdb` and seeds all tables with exercises, protocols, and user settings.

```powershell
python init_db.py
```

You should see:
```
Database initialized and seeded.
```

---

### Step 3 — Run the Backend Server

```powershell
uvicorn main:app --reload
```

The API will be available at:
- 🌐 **Base URL:** http://127.0.0.1:8000
- 📖 **Swagger UI (interactive docs):** http://127.0.0.1:8000/docs
- 📄 **ReDoc docs:** http://127.0.0.1:8000/redoc

> Keep this terminal window **open** while using the app.

---

### Step 4 — Set Up the Flutter Frontend

Open a **new terminal window**, then:

#### 4a. Navigate to the frontend directory

```powershell
cd fitness/frontend
```

#### 4b. Install Flutter dependencies

```powershell
flutter pub get
```

#### 4c. Run the Flutter app

```powershell
flutter run
```

Flutter will prompt you to select a target device (Windows desktop, Chrome, or a connected Android/iOS device). Select your preferred option.

---

### Step 5 — (Optional) Enable the AI Coach with Ollama

The Coach screen has a **"Ask Coach"** button and **"Why?"** explanation buttons that use a local LLM. To enable them:

#### 5a. Install Ollama

Download from: https://ollama.com/

#### 5b. Pull and run the llama3 model

```powershell
ollama pull llama3
ollama run llama3
```

> Leave this running in its own terminal. The FastAPI backend will automatically connect to it at `http://localhost:11434`.

If Ollama is not running, the Coach screen will still work — it will just show `"LLM backend unavailable"` instead of AI-generated explanations.

---

### Step 6 — (Optional) Import Historic Workout Data

If you have past workout data, you can import it using the CSV importer.

#### CSV format

Your CSV file must have these column headers:

```
date,template,exercise,set_number,reps,weight,rir,rpe
```

**Example:**
```csv
date,template,exercise,set_number,reps,weight,rir,rpe
2026-06-01,FullBodyA,Squat (goblet),1,10,30.0,2,8
2026-06-01,FullBodyA,Push-up,2,12,0.0,3,7
2026-06-03,FullBodyB,Romanian deadlift,1,10,40.0,2,8
```

> The `exercise` column must exactly match a name in the `exercises` table.

#### Run the import

```powershell
cd backend
.venv\Scripts\Activate.ps1
python import_data.py path\to\your_workout_data.csv
```

---

## 🧪 Running Tests

### Backend tests (pytest)

```powershell
cd backend
.venv\Scripts\Activate.ps1
pytest test_main.py -v
```

Expected output:
```
test_main.py::test_log_session PASSED
test_main.py::test_analytics_and_suggestions PASSED
2 passed in 0.47s
```

### Flutter tests

```powershell
cd frontend
flutter test
```

---

## 📡 API Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/sessions` | Log a complete workout session |
| `GET` | `/analytics/weekly` | Weekly volume analytics by muscle group |
| `GET` | `/protocols?template=FullBodyA` | Get warm-up / cool-down protocols for a template |
| `GET` | `/settings` | Get user goal configuration |
| `GET` | `/suggestions/next` | Get AI coaching suggestions and next template |
| `POST` | `/coach/explain` | Explain a suggestion using the local LLM |
| `POST` | `/coach/chat` | Ask a fitness question to the local LLM |

Full interactive docs with request/response schemas: **http://127.0.0.1:8000/docs**

---

## 🎯 Workout Templates

| Template | Focus |
|---|---|
| `FullBodyA` | Squat, Push-up, Hip thrust, Horizontal row, Calf raise, Plank |
| `FullBodyB` | Bulgarian split squat, Romanian deadlift, Overhead push, Single-leg glute bridge, Side plank |

The app automatically alternates between templates and provides warm-up/cool-down protocols for each.

---

## 🧠 Coaching Logic

The Coach screen uses **MEV/MRV volume landmarks** based on your goal (set in `user_settings`):

| Goal | MEV (Minimum Effective Volume) | MRV (Maximum Recoverable Volume) |
|---|---|---|
| `muscle_gain` | 10 hard sets/muscle/week | 20 hard sets/muscle/week |
| `strength` | 8 hard sets/muscle/week | 15 hard sets/muscle/week |
| `endurance` | 6 hard sets/muscle/week | 10 hard sets/muscle/week |

A **hard set** is defined as: `RIR ≤ 3` OR `RPE ≥ 7`.

---

## 🗂️ Database Tables

| Table | Purpose |
|---|---|
| `exercises` | Exercise catalog with muscle group mapping |
| `workout_sessions` | One row per training session |
| `session_sets` | One row per set logged in a session |
| `warmup_cooldown_protocols` | Step-by-step warm-up and cool-down instructions |
| `user_settings` | User goal, frequency preference, equipment |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile / Desktop UI | Flutter (Dart) |
| Charts | fl_chart |
| HTTP Client | http (Dart) |
| Backend API | FastAPI (Python) |
| Local Database | DuckDB |
| Data Validation | Pydantic v2 |
| AI Coach | Ollama (llama3) — local LLM, optional |
| Testing | pytest + Flutter test |

---

## 📝 License

MIT — feel free to use, modify, and distribute.
