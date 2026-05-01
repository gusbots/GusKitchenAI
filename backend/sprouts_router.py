from datetime import datetime, timezone
from fastapi import APIRouter, Body

import backend.sprouts as sprouts

router = APIRouter()

@router.get("/seeds")
def get_seeds():
    """
    Retrieve available seed types and sprouting rules.
    """
    return sprouts.load_seeds()


@router.get("/sprouts")
def get_sprouts():
    """
    Retrieve enriched sprout batches.
    """
    return sprouts.get_enriched_sprouts()


@router.post("/sprouts")
def create_sprout(data: dict = Body(...)):
    """
    Create a new sprout batch.
    """
    sprout_list = sprouts.load_sprouts()

    if sprout_list:
        new_id = max(s["id"] for s in sprout_list) + 1
    else:
        new_id = 1

    new_sprout = {
        "id": new_id,
        "seed_id": data["seed_id"],
        "start_time": datetime.now(timezone.utc).isoformat(),
        "phase": "soaking",
        "wash_log": []
    }

    sprout_list.append(new_sprout)
    sprouts.save_sprouts_file(sprout_list)

    return {"status": "created", "sprout": new_sprout}


@router.post("/sprouts/{sprout_id}/done-soaking")
def done_soaking(sprout_id: int):
    """
    Mark sprout as done soaking.
    """
    sprout_list = sprouts.load_sprouts()

    for sprout in sprout_list:
        if sprout["id"] == sprout_id:
            sprout["phase"] = "growing"
            sprouts.save_sprouts_file(sprout_list)
            return {"status": "updated", "sprout": sprout}

    return {"status": "not_found"}


@router.post("/sprouts/{sprout_id}/wash")
def add_wash(sprout_id: int):
    """
    Record a wash for today.
    """
    sprout_list = sprouts.load_sprouts()
    today = datetime.utcnow().date().isoformat()

    for sprout in sprout_list:
        if sprout["id"] == sprout_id:
            log = sprout.get("wash_log", [])

            for entry in log:
                if entry["date"] == today:
                    entry["count"] += 1
                    break
            else:
                log.append({
                    "date": today,
                    "count": 1
                })

            sprout["wash_log"] = log
            sprouts.save_sprouts_file(sprout_list)

            return {"status": "updated", "sprout": sprout}

    return {"status": "not_found"}


@router.post("/sprouts/{sprout_id}/done-growing")
def done_growing(sprout_id: int):
    """
    Mark sprout as harvested.
    """
    sprout_list = sprouts.load_sprouts()

    for sprout in sprout_list:
        if sprout["id"] == sprout_id:
            sprout["phase"] = "done"
            sprouts.save_sprouts_file(sprout_list)
            return {"status": "updated", "sprout": sprout}

    return {"status": "not_found"}
