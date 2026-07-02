from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, func, or_, select
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
    limit: int = Query(20, ge=1, le=500),
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

    # Skills filter (OR logic) — DB-side. skills is stored as a JSON array
    # string, so anchoring on the surrounding quotes gives whole-token match
    # ("java" must not hit "javascript"); ilike keeps it case-insensitive.
    if skills:
        skill_list = [s.strip() for s in skills.split(",") if s.strip()]
        stmt = stmt.where(
            or_(*[Job.skills.ilike(f'%"{s}"%') for s in skill_list])
        )

    total = session.exec(
        select(func.count()).select_from(stmt.subquery())
    ).one()
    paginated = session.exec(
        stmt.offset((page - 1) * limit).limit(limit)
    ).all()

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
