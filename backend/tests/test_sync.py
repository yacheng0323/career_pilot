import json
from unittest.mock import AsyncMock, patch

from backend.models.job import Job, JobCreate


def test_sync_status_initial(client):
    resp = client.get("/api/v1/sync/status")
    assert resp.status_code == 200
    data = resp.json()
    assert "lastSync" in data
    assert "status" in data


def test_trigger_sync_returns_ok(client):
    with patch(
        "backend.routers.sync.run_all_crawlers",
        new_callable=AsyncMock,
        return_value=3,
    ):
        resp = client.post("/api/v1/sync")
    assert resp.status_code == 200
    assert resp.json()["jobsUpserted"] == 3


def test_trigger_sync_handles_crawler_error(client):
    with patch(
        "backend.routers.sync.run_all_crawlers",
        new_callable=AsyncMock,
        side_effect=Exception("network error"),
    ):
        resp = client.post("/api/v1/sync")
    assert resp.status_code == 500
    assert "error" in resp.json()["detail"].lower()


def _job_create(**overrides) -> JobCreate:
    base = dict(
        id="j1", title="Dev", company="Acme", location="台北市",
        is_remote=False, salary_range="80K", skills=["Python"],
        description="desc", source="104", url="https://a.example.com",
    )
    base.update(overrides)
    return JobCreate(**base)


def test_upsert_updates_all_mutable_fields(session, monkeypatch):
    from backend import scheduler

    monkeypatch.setattr(scheduler, "engine", session.get_bind())

    scheduler._upsert_jobs([_job_create()])
    scheduler._upsert_jobs([_job_create(
        title="Senior Dev", company="Beta", location="台中市",
        is_remote=True, salary_range="100K", skills=["Go"],
        url="https://b.example.com",
    )])

    job = session.get(Job, "j1")
    session.refresh(job)
    assert job.title == "Senior Dev"
    assert job.company == "Beta"
    assert job.location == "台中市"
    assert job.is_remote is True
    assert job.salary_range == "100K"
    assert json.loads(job.skills) == ["Go"]
    assert job.url == "https://b.example.com"


def test_upsert_preserves_enriched_fields_when_new_empty(session, monkeypatch):
    """Partial enrichment: a later crawl without detail data (empty skills /
    description) must not clobber previously enriched values."""
    from backend import scheduler

    monkeypatch.setattr(scheduler, "engine", session.get_bind())

    scheduler._upsert_jobs([_job_create(skills=["Python"], description="rich")])
    scheduler._upsert_jobs([_job_create(title="Renamed", skills=[], description="")])

    job = session.get(Job, "j1")
    session.refresh(job)
    assert job.title == "Renamed"                    # normal field still updates
    assert json.loads(job.skills) == ["Python"]      # preserved
    assert job.description == "rich"                 # preserved
