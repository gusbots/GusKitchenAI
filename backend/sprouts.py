import json
from pathlib import Path

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