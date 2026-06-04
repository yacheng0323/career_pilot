from contextlib import asynccontextmanager
from fastapi import FastAPI
from backend.database import init_db
from backend.routers import jobs, sync
from backend.scheduler import create_scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    scheduler = create_scheduler()
    scheduler.start()
    yield
    scheduler.shutdown()


app = FastAPI(title="Career Pilot API", lifespan=lifespan)
app.include_router(jobs.router, prefix="/api/v1")
app.include_router(sync.router, prefix="/api/v1")


@app.get("/health")
def health():
    return {"status": "ok"}
