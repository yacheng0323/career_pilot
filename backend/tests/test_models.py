from backend.models.job import Job, JobResponse
from datetime import datetime


def test_job_model_fields():
    job = Job(
        id="104_12345",
        title="Flutter Engineer",
        company="Acme",
        location="台北市",
        is_remote=False,
        salary_range="80K-120K",
        skills='["Flutter","Dart"]',
        description="Build apps",
        source="104",
        url="https://example.com/job/12345",
        crawled_at=datetime(2026, 6, 4),
    )
    assert job.id == "104_12345"
    assert job.source == "104"


def test_job_response_skills_is_list():
    resp = JobResponse(
        id="104_12345",
        title="Flutter Engineer",
        company="Acme",
        location="台北市",
        isRemote=False,
        salaryRange="80K-120K",
        skills=["Flutter", "Dart"],
        description="Build apps",
        source="104",
        url="https://example.com/job/12345",
        crawledAt=datetime(2026, 6, 4),
    )
    assert isinstance(resp.skills, list)
    assert resp.skills[0] == "Flutter"


def test_job_response_from_job():
    import json
    job = Job(
        id="cake_001",
        title="React Dev",
        company="StartupX",
        location="台中市",
        is_remote=True,
        salary_range="60K-90K",
        skills=json.dumps(["React", "TypeScript"]),
        description="Build web apps",
        source="cake",
        url="https://cake.com/jobs/001",
        crawled_at=datetime(2026, 6, 4),
    )
    resp = JobResponse.from_job(job)
    assert resp.isRemote is True
    assert resp.salaryRange == "60K-90K"
    assert resp.skills == ["React", "TypeScript"]
    assert resp.crawledAt == datetime(2026, 6, 4)
