from fastapi import APIRouter, HTTPException
from backend.scheduler import run_all_crawlers, get_sync_status

router = APIRouter(tags=["sync"])


@router.post("/sync")
async def trigger_sync():
    try:
        count = await run_all_crawlers()
        return {"status": "ok", "jobsUpserted": count}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sync error: {e}")


@router.get("/sync/status")
def sync_status():
    return get_sync_status()
