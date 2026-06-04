from fastapi import APIRouter

router = APIRouter(tags=["sync"])


@router.post("/sync")
def trigger_sync():
    return {"status": "ok", "message": "sync not yet implemented"}


@router.get("/sync/status")
def sync_status():
    return {"lastSync": None, "status": "idle"}
