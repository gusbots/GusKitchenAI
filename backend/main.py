import json
from pathlib import Path
from datetime import datetime, timezone

from fastapi import Body
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

from backend.sprouts import load_seeds, load_sprouts, save_sprouts_file

app = FastAPI()
app.mount("/static", StaticFiles(directory="frontend"), name="static")

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

@app.get("/", response_class=HTMLResponse)
def root():
    with open("frontend/index.html") as f:
        return f.read()


@app.get("/health")
def health():
    return {"status": "ok"}


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


@app.get("/calendar")
def get_calendar():
    return [
        {"time": "9:00 AM", "event": "Team Meeting"},
        {"time": "12:00 PM", "event": "Lunch"},
        {"time": "6:00 PM", "event": "Cook Dinner"}
    ]


@app.get("/seeds")
def get_seeds():
    """
    Retrieve available seed types and sprouting rules.
    """
    return load_seeds()


@app.get("/sprouts")
def get_sprouts():
    """
    Retrieve active sprout batches with seed rule details.
    """
    sprouts = load_sprouts()
    seeds = load_seeds()

    enriched_sprouts = []

    for sprout in sprouts:
        seed = seeds.get(sprout["seed_id"], {})

        enriched_sprout = {
            **sprout,
            "seed_name": seed.get("name", sprout["seed_id"]),
            "soak_hours": seed.get("soak_hours"),
            "grow_days": seed.get("grow_days"),
            "washes_per_day": seed.get("washes_per_day")
        }

        enriched_sprouts.append(enriched_sprout)

    return enriched_sprouts


@app.post("/sprouts")
def create_sprout(data: dict = Body(...)):
    """
    Create a new sprout batch.
    """

    sprouts = load_sprouts()

    if sprouts:
        new_id = max(s["id"] for s in sprouts) + 1
    else:
        new_id = 1

    new_sprout = {
        "id": new_id,
        "seed_id": data["seed_id"],
        "start_time": datetime.now(timezone.utc).isoformat(),
        "phase": "soaking",
        "wash_log": []
    }

    sprouts.append(new_sprout)
    save_sprouts_file(sprouts)

    return {"status": "created", "sprout": new_sprout}

@app.post("/sprouts/{sprout_id}/done-soaking")
def done_soaking(sprout_id: int):
    """
    Mark a sprout batch as done soaking and move it to growing phase.
    """
    sprouts = load_sprouts()

    for sprout in sprouts:
        if sprout["id"] == sprout_id:
            sprout["phase"] = "growing"
            save_sprouts_file(sprouts)
            return {"status": "updated", "sprout": sprout}

    return {"status": "not_found"}