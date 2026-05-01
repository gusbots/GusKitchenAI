import json
from pathlib import Path
from datetime import datetime, timezone

# -------------------------
# Sprout File Management
# -------------------------

SEEDS_FILE = Path("database/json/seeds.json")
SPROUTS_FILE = Path("database/json/sprouts.json")


def load_seeds():
    """
    Load seed rules from the JSON file.

    Returns:
        dict: Available seed types and their sprouting rules.
    """
    with open(SEEDS_FILE, "r") as f:
        return json.load(f)


def load_sprouts():
    """
    Load active sprout batches from the JSON file.

    Returns:
        list: Active sprout batches.
    """
    with open(SPROUTS_FILE, "r") as f:
        return json.load(f)


def save_sprouts_file(data):
    """
    Save active sprout batches to the JSON file.

    Args:
        data (list): Sprout batch data to save.
    """
    with open(SPROUTS_FILE, "w") as f:
        json.dump(data, f, indent=2)


def get_enriched_sprouts():
    """
    Load sprout batches and enrich them with calculated state.

    Returns:
        list: Sprout batches with seed rules and calculated numeric state.
    """
    sprouts = load_sprouts()
    seeds = load_seeds()

    enriched_sprouts = []

    for sprout in sprouts:
        seed = seeds.get(sprout["seed_id"], {})

        soak_hours = seed.get("soak_hours", 0)
        grow_days = seed.get("grow_days", 0)
        washes_per_day = seed.get("washes_per_day", 0)

        start = datetime.fromisoformat(sprout["start_time"])
        now = datetime.now(timezone.utc)

        if start.tzinfo is None:
            start = start.replace(tzinfo=timezone.utc)

        elapsed_seconds = (now - start).total_seconds()
        elapsed_hours = elapsed_seconds / 3600
        elapsed_days = elapsed_seconds / 86400
        current_day = int(elapsed_days) + 1

        today = now.date().isoformat()
        wash_log = sprout.get("wash_log", [])
        today_log = next((entry for entry in wash_log if entry["date"] == today), None)
        washes_done_today = today_log["count"] if today_log else 0

        enriched_sprout = {
            **sprout,
            "seed_name": seed.get("name", sprout["seed_id"]),
            "soak_hours": soak_hours,
            "grow_days": grow_days,
            "washes_per_day": washes_per_day,

            "elapsed_hours": round(elapsed_hours, 2),
            "elapsed_days": round(elapsed_days, 2),
            "current_day": current_day,

            "soaking_complete": elapsed_hours >= soak_hours,
            "is_ready_to_harvest": current_day >= grow_days,

            "washes_done_today": washes_done_today,

            "can_mark_soaking_done": sprout["phase"] == "soaking",
            "can_wash": sprout["phase"] == "growing",
            "can_harvest": sprout["phase"] == "growing"
        }

        enriched_sprouts.append(enriched_sprout)

    return enriched_sprouts