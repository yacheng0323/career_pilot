import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from backend.database import get_session
from backend.models.job import Job, JobResponse

router = APIRouter(tags=["jobs"])


@router.get("/jobs", response_model=dict)
def list_jobs(
    q: str | None = Query(None),
    location: str | None = Query(None),
    remote: bool | None = Query(None),
    skills: str | None = Query(None),
    source: str | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    session: Session = Depends(get_session),
):
    stmt = select(Job)

    if q:
        stmt = stmt.where(
            Job.title.ilike(f"%{q}%")
            | Job.company.ilike(f"%{q}%")
        )
    if location:
        stmt = stmt.where(Job.location == location)
    if remote is not None:
        stmt = stmt.where(Job.is_remote == remote)
    if source:
        stmt = stmt.where(Job.source == source)

    all_jobs = session.exec(stmt).all()

    # Skills filter (OR logic) — done in Python after DB fetch
    if skills:
        skill_list = [s.strip().lower() for s in skills.split(",")]
        all_jobs = [
            j for j in all_jobs
            if any(
                s in [sk.lower() for sk in json.loads(j.skills)]
                for s in skill_list
            )
        ]

    total = len(all_jobs)
    offset = (page - 1) * limit
    paginated = all_jobs[offset: offset + limit]

    return {
        "items": [JobResponse.from_job(j).model_dump() for j in paginated],
        "total": total,
        "page": page,
        "limit": limit,
    }


@router.get("/jobs/{job_id}", response_model=JobResponse)
def get_job(job_id: str, session: Session = Depends(get_session)):
    job = session.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    return JobResponse.from_job(job)
