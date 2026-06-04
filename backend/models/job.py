import json
from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field
from pydantic import BaseModel


class Job(SQLModel, table=True):
    id: str = Field(primary_key=True)
    title: str
    company: str
    location: str
    is_remote: bool = False
    salary_range: str = ""
    skills: str = "[]"          # JSON array stored as string
    description: str = ""
    source: str
    url: str
    crawled_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = None


class JobCreate(BaseModel):
    """Used internally by crawlers."""
    id: str
    title: str
    company: str
    location: str
    is_remote: bool
    salary_range: str
    skills: list[str]
    description: str
    source: str
    url: str


class JobResponse(BaseModel):
    """Returned by API — camelCase for Flutter compatibility."""
    id: str
    title: str
    company: str
    location: str
    isRemote: bool
    salaryRange: str
    skills: list[str]
    description: str
    source: str
    url: str
    crawledAt: datetime

    @classmethod
    def from_job(cls, job: Job) -> "JobResponse":
        return cls(
            id=job.id,
            title=job.title,
            company=job.company,
            location=job.location,
            isRemote=job.is_remote,
            salaryRange=job.salary_range,
            skills=json.loads(job.skills),
            description=job.description,
            source=job.source,
            url=job.url,
            crawledAt=job.crawled_at,
        )
