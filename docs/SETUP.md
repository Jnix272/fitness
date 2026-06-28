# Personal Workout Coach App — Step-by-Step Guide

This is a quick-reference card for getting the app running from scratch.

---

## ⚡ Quick Start (Summary)

```
1. cd backend && python -m venv .venv && .venv\Scripts\Activate.ps1
2. pip install fastapi[all] uvicorn duckdb pydantic pytest httpx
3. python init_db.py
4. uvicorn main:app --reload          ← keep running
5. (new terminal) cd frontend
6. flutter pub get && flutter run
7. (optional) ollama run llama3       ← for AI Coach
```

---

## Step 1 — Prerequisites

Install these tools before starting:

| Tool | Install |
|---|---|
| **Python 3.10+** | https://www.python.org/downloads/ |
| **Flutter 3.0+** | https://docs.flutter.dev/get-started/install |
| **Git** | https://git-scm.com/ |
| **Ollama** *(optional, for AI Coach)* | https://ollama.com/ |

---

## Step 2 — Clone the Project

```powershell
git clone <your-repo-url>
cd fitness
```

---

## Step 3 — Backend Setup

```powershell
cd backend
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install fastapi[all] uvicorn duckdb pydantic pytest httpx
python init_db.py
```

✅ You should see: `Database initialized and seeded.`

---

## Step 4 — Start the Backend

```powershell
uvicorn main:app --reload
```

- API: http://127.0.0.1:8000
- Docs: http://127.0.0.1:8000/docs

> **Leave this terminal open.**

---

## Step 5 — Frontend Setup & Run

Open a **new terminal**:

```powershell
cd fitness/frontend
flutter pub get
flutter run
```

Select your target device when prompted (Windows desktop, Chrome, Android, iOS).

---

## Step 6 — (Optional) AI Coach

```powershell
ollama pull llama3
ollama run llama3
```

Leave running in its own terminal. The Coach screen will automatically use it.

---

## Step 7 — (Optional) Import Workout History

Prepare a CSV with columns: `date, template, exercise, set_number, reps, weight, rir, rpe`

```powershell
cd backend
.venv\Scripts\Activate.ps1
python import_data.py path\to\workouts.csv
```

---

## Step 8 — Run Tests

```powershell
# Backend
cd backend && .venv\Scripts\Activate.ps1
pytest test_main.py -v

# Frontend
cd frontend
flutter test
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| `ModuleNotFoundError` | Make sure `.venv` is activated (`(.venv)` in prompt) |
| Flutter can't connect to backend | Ensure backend is running on port 8000 |
| AI Coach says "LLM unavailable" | Start Ollama: `ollama run llama3` |
| `flutter run` — no devices found | Connect a device or enable Windows desktop: `flutter config --enable-windows-desktop` |
| Database errors on re-init | Delete `workouts.duckdb` and re-run `python init_db.py` |
