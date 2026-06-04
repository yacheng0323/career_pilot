from contextlib import asynccontextmanager
from fastapi import FastAPI
from backend.database import init_db
from backend.routers import jobs, sync


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="Career Pilot API", lifespan=lifespan)
app.include_router(jobs.router, prefix="/api/v1")
app.include_router(sync.router, prefix="/api/v1")


@app.get("/health")
def health():
    return {"status": "ok"}
