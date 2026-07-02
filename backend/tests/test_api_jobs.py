import json
from datetime import datetime
from backend.models.job import Job


def _make_job(session, id="104_001", title="Flutter Dev", source="104",
              location="台北市", is_remote=False, skills=None):
    skills = skills or ["Flutter", "Dart"]
    job = Job(
        id=id, title=title, company="Acme", location=location,
        is_remote=is_remote, salary_range="80K", skills=json.dumps(skills),
        description="desc", source=source, url="https://example.com",
        crawled_at=datetime(2026, 6, 4),
    )
    session.add(job)
    session.commit()
    return job


def test_get_jobs_empty(client):
    resp = client.get("/api/v1/jobs")
    assert resp.status_code == 200
    data = resp.json()
    assert data["items"] == []
    assert data["total"] == 0


def test_get_jobs_returns_job(client, session):
    _make_job(session)
    resp = client.get("/api/v1/jobs")
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["title"] == "Flutter Dev"
    assert isinstance(items[0]["skills"], list)


def test_get_jobs_keyword_filter(client, session):
    _make_job(session, id="j1", title="Flutter Dev")
    _make_job(session, id="j2", title="iOS Engineer")
    resp = client.get("/api/v1/jobs?q=flutter")
    items = resp.json()["items"]
    assert len(items) == 1
    assert items[0]["title"] == "Flutter Dev"


def test_get_jobs_remote_filter(client, session):
    _make_job(session, id="j1", is_remote=True)
    _make_job(session, id="j2", is_remote=False)
    resp = client.get("/api/v1/jobs?remote=true")
    assert len(resp.json()["items"]) == 1


def test_get_jobs_location_filter(client, session):
    _make_job(session, id="j1", location="台北市")
    _make_job(session, id="j2", location="台中市")
    resp = client.get("/api/v1/jobs?location=台北市")
    assert len(resp.json()["items"]) == 1


def test_get_job_by_id(client, session):
    _make_job(session, id="104_001")
    resp = client.get("/api/v1/jobs/104_001")
    assert resp.status_code == 200
    assert resp.json()["id"] == "104_001"


def test_get_job_by_id_not_found(client):
    resp = client.get("/api/v1/jobs/nonexistent")
    assert resp.status_code == 404


def test_get_jobs_pagination(client, session):
    for i in range(5):
        _make_job(session, id=f"j{i}", title=f"Job {i}")
    resp = client.get("/api/v1/jobs?page=1&limit=2")
    data = resp.json()
    assert len(data["items"]) == 2
    assert data["total"] == 5


def test_get_jobs_skills_filter_or_logic(client, session):
    _make_job(session, id="j1", skills=["Python", "SQL"])
    _make_job(session, id="j2", skills=["Flutter", "Dart"])
    _make_job(session, id="j3", skills=["Go"])
    resp = client.get("/api/v1/jobs?skills=python,dart")
    ids = {item["id"] for item in resp.json()["items"]}
    assert ids == {"j1", "j2"}


def test_get_jobs_skills_filter_case_insensitive(client, session):
    _make_job(session, id="j1", skills=["PYTHON"])
    resp = client.get("/api/v1/jobs?skills=python")
    assert len(resp.json()["items"]) == 1


def test_get_jobs_skills_filter_no_partial_match(client, session):
    _make_job(session, id="j1", skills=["JavaScript"])
    _make_job(session, id="j2", skills=["Java"])
    resp = client.get("/api/v1/jobs?skills=java")
    ids = {item["id"] for item in resp.json()["items"]}
    assert ids == {"j2"}


def test_get_jobs_skills_filter_with_pagination_total(client, session):
    for i in range(5):
        _make_job(session, id=f"py{i}", skills=["Python"])
    _make_job(session, id="other", skills=["Go"])
    resp = client.get("/api/v1/jobs?skills=python&page=1&limit=2")
    data = resp.json()
    assert data["total"] == 5
    assert len(data["items"]) == 2
