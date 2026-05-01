import json
from pathlib import Path

from fastapi import Body
from fastapi import FastAPI
from fastapi.responses import HTMLResponse

app = FastAPI()

# -------------------------
# Settings File Management
# -------------------------

SETTINGS_FILE = Path("database/json/settings.json")


def load_settings():
    """
    Load settings from the JSON file.

    Returns:
        dict: Current settings stored in the file.
    """
    with open(SETTINGS_FILE, "r") as f:
        return json.load(f)


def save_settings_file(data):
    """
    Save settings to the JSON file.

    Args:
        data (dict): Settings data to be saved.

    This will overwrite the existing file.
    """
    with open(SETTINGS_FILE, "w") as f:
        json.dump(data, f, indent=2)

# -------------------------
# API Endpoints
# -------------------------

@app.get("/settings")
def get_settings():
    """
    Retrieve current settings.

    Returns:
        dict: Current settings from file.
    """
    return load_settings()

@app.post("/settings")
def save_settings(data: dict = Body(...)):
    """
    Update and save settings.

    Args:
        data (dict): New settings data from request body.

    Returns:
        dict: Status message confirming save.
    """
    current = load_settings()
    current.update(data)
    save_settings_file(current)

    return {"status": "saved"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/", response_class=HTMLResponse)
def root():
    with open("frontend/index.html") as f:
        return f.read()

@app.get("/calendar")
def get_calendar():
    return [
        {"time": "9:00 AM", "event": "Team Meeting"},
        {"time": "12:00 PM", "event": "Lunch"},
        {"time": "6:00 PM", "event": "Cook Dinner"}
    ]