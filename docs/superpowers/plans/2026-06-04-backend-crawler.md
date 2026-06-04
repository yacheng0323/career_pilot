# Backend Crawler Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Python FastAPI + SQLite 後端服務，提供職缺 REST API，並以 APScheduler 定期爬取 CakeResume 和 104 職缺。

**Architecture:** FastAPI 處理 HTTP 請求，SQLModel 管理 SQLite DB，兩個 httpx-based 爬蟲（CakeResume、104）實作 `BaseCrawler` 介面，APScheduler 每 6 小時觸發一次爬蟲。Flutter App 透過 Dio 呼叫 API。

**Tech Stack:** Python 3.11+, FastAPI, SQLModel, SQLite, httpx, BeautifulSoup4, APScheduler, pytest, pytest-asyncio

---

## File Structure

```
backend/
├── main.py                        # FastAPI app + lifespan（啟動 scheduler）
├── database.py                    # SQLite engine + session factory
├── models/
│   └── job.py                     # Job SQLModel + JobResponse Pydantic
├── routers/
│   ├── jobs.py                    # GET /api/v1/jobs, GET /api/v1/jobs/{id}
│   └── sync.py                    # POST /api/v1/sync, GET /api/v1/sync/status
├── crawlers/
│   ├── base.py                    # BaseCrawler ABC + JobCreate schema
│   ├── crawler_cake.py            # CakeResume httpx crawler
│   └── crawler_104.py             # 104 httpx crawler
├── scheduler.py                   # APScheduler setup
├── requirements.txt
└── tests/
    ├── conftest.py                # pytest fixtures（test DB, test client）
    ├── test_api_jobs.py           # GET /jobs 端點測試
    ├── test_crawler_cake.py       # CakeResume 爬蟲測試（mock httpx）
    ├── test_crawler_104.py        # 104 爬蟲測試（mock httpx）
    └── test_sync.py               # sync endpoint 測試
```

---

## Task 1: 專案初始化 + 依賴安裝

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/.gitignore`

- [ ] **Step 1: 建立 backend 目錄結構**

```powershell
mkdir C:\dev\career_pilot\backend
mkdir C:\dev\career_pilot\backend\models
mkdir C:\dev\career_pilot\backend\routers
mkdir C:\dev\career_pilot\backend\crawlers
mkdir C:\dev\career_pilot\backend\tests
```

- [ ] **Step 2: 建立 requirements.txt**

```
# C:\dev\career_pilot\backend\requirements.txt
fastapi==0.115.0
uvicorn[standard]==0.30.6
sqlmodel==0.0.21
httpx==0.27.2
beautifulsoup4==4.12.3
apscheduler==3.10.4
pytest==8.3.3
pytest-asyncio==0.24.0
pytest-mock==3.14.0
respx==0.21.1
```

- [ ] **Step 3: 建立 .gitignore**

```
# C:\dev\career_pilot\backend\.gitignore
__pycache__/
*.pyc
.venv/
*.db
.env
```

- [ ] **Step 4: 建立虛擬環境並安裝依賴**

```powershell
cd C:\dev\career_pilot\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Expected: 所有套件安裝成功，無 error。

- [ ] **Step 5: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/requirements.txt backend/.gitignore
git commit -m "chore: init backend project structure"
```

---

## Task 2: 資料模型（Job SQLModel + JobResponse）

**Files:**
- Create: `backend/models/job.py`
- Create: `backend/models/__init__.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_models.py
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
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest tests/test_models.py -v
```

Expected: `ModuleNotFoundError: No module named 'backend.models.job'`

- [ ] **Step 3: 實作模型**

```python
# backend/models/__init__.py
# (empty)
```

```python
# backend/models/job.py
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
```

- [ ] **Step 4: 執行測試確認通過**

```powershell
pytest tests/test_models.py -v
```

Expected: 2 passed

- [ ] **Step 5: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/models/
git commit -m "feat(backend): add Job SQLModel and JobResponse schema"
```

---

## Task 3: 資料庫初始化

**Files:**
- Create: `backend/database.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_database.py
from backend.database import get_session, init_db
from backend.models.job import Job
from sqlmodel import Session, select

def test_init_db_creates_table():
    # Uses in-memory SQLite
    session_gen = get_session()
    session = next(session_gen)
    # If table doesn't exist this will raise
    results = session.exec(select(Job)).all()
    assert isinstance(results, list)
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
pytest tests/test_database.py -v
```

Expected: `ModuleNotFoundError: No module named 'backend.database'`

- [ ] **Step 3: 實作 database.py**

```python
# backend/database.py
import os
from sqlmodel import SQLModel, Session, create_engine

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./career_pilot.db")

# check_same_thread=False required for SQLite + FastAPI
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)


def init_db():
    """Create all tables. Call once at startup."""
    SQLModel.metadata.create_all(engine)


def get_session():
    """FastAPI dependency — yields a DB session."""
    with Session(engine) as session:
        yield session
```

- [ ] **Step 4: 更新 conftest.py 讓測試用 in-memory DB**

```python
# backend/tests/conftest.py
import pytest
from sqlmodel import SQLModel, Session, create_engine, StaticPool
from backend.database import get_session
from backend.models.job import Job  # noqa: F401 — needed for table creation


TEST_DATABASE_URL = "sqlite://"   # in-memory


@pytest.fixture(name="session")
def session_fixture():
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session: Session):
    from fastapi.testclient import TestClient
    from backend.main import app

    def override_get_session():
        yield session

    app.dependency_overrides[get_session] = override_get_session
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()
```

- [ ] **Step 5: 執行測試確認通過**

```powershell
pytest tests/test_database.py -v
```

Expected: 1 passed

- [ ] **Step 6: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/database.py backend/tests/conftest.py
git commit -m "feat(backend): add SQLite database setup and test fixtures"
```

---

## Task 4: Jobs API Router（GET /jobs, GET /jobs/{id}）

**Files:**
- Create: `backend/routers/jobs.py`
- Create: `backend/routers/__init__.py`
- Create: `backend/tests/test_api_jobs.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_api_jobs.py
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
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
pytest tests/test_api_jobs.py -v
```

Expected: ImportError（main.py 尚未建立）

- [ ] **Step 3: 建立 main.py（最小版本）**

```python
# backend/main.py
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
```

- [ ] **Step 4: 建立 routers/__init__.py**

```python
# backend/routers/__init__.py
# (empty)
```

- [ ] **Step 5: 實作 jobs router**

```python
# backend/routers/jobs.py
import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlmodel import Session, select
from backend.database import get_session
from backend.models.job import Job, JobResponse

router = APIRouter(tags=["jobs"])


class JobListResponse:
    pass


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
        q_lower = q.lower()
        stmt = stmt.where(
            Job.title.ilike(f"%{q}%")
            | Job.company.ilike(f"%{q}%")
            | Job.skills.ilike(f"%{q}%")
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
            if any(s in [sk.lower() for sk in json.loads(j.skills)]
                   for s in skill_list)
        ]

    total = len(all_jobs)
    offset = (page - 1) * limit
    paginated = all_jobs[offset: offset + limit]

    return {
        "items": [JobResponse.from_job(j) for j in paginated],
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
```

- [ ] **Step 6: 建立 sync router（最小版本，Task 6 完整實作）**

```python
# backend/routers/sync.py
from fastapi import APIRouter

router = APIRouter(tags=["sync"])


@router.post("/sync")
def trigger_sync():
    return {"status": "ok", "message": "sync not yet implemented"}


@router.get("/sync/status")
def sync_status():
    return {"lastSync": None, "status": "idle"}
```

- [ ] **Step 7: 執行測試確認通過**

```powershell
pytest tests/test_api_jobs.py -v
```

Expected: 8 passed

- [ ] **Step 8: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/
git commit -m "feat(backend): add jobs API router with filtering and pagination"
```

---

## Task 5: BaseCrawler + CakeResume 爬蟲

**Files:**
- Create: `backend/crawlers/__init__.py`
- Create: `backend/crawlers/base.py`
- Create: `backend/crawlers/crawler_cake.py`
- Create: `backend/tests/test_crawler_cake.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_crawler_cake.py
import pytest
import respx
import httpx
from backend.crawlers.crawler_cake import CakeResumeCrawler


MOCK_CAKE_RESPONSE = {
    "data": [
        {
            "id": 99001,
            "title": "Flutter Engineer",
            "company": {"name": "TestCo"},
            "location": {"name": "Taipei"},
            "remote_working_enabled": True,
            "salary_string": "800K-1.2M",
            "required_skills": [{"name": "Flutter"}, {"name": "Dart"}],
            "description": "Build awesome apps.",
            "url": "https://www.cakeresume.com/jobs/flutter-engineer-99001",
        }
    ]
}


@pytest.mark.asyncio
@respx.mock
async def test_cake_fetch_returns_jobs():
    respx.get("https://www.cakeresume.com/api/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_CAKE_RESPONSE)
    )
    crawler = CakeResumeCrawler()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "cake_99001"
    assert jobs[0].title == "Flutter Engineer"
    assert jobs[0].is_remote is True
    assert "Flutter" in jobs[0].skills


@pytest.mark.asyncio
@respx.mock
async def test_cake_fetch_handles_http_error():
    respx.get("https://www.cakeresume.com/api/jobs").mock(
        return_value=httpx.Response(503)
    )
    crawler = CakeResumeCrawler()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert jobs == []   # graceful degradation
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
pytest tests/test_crawler_cake.py -v
```

Expected: `ModuleNotFoundError`

- [ ] **Step 3: 實作 BaseCrawler**

```python
# backend/crawlers/__init__.py
# (empty)
```

```python
# backend/crawlers/base.py
import asyncio
import random
from abc import ABC, abstractmethod
from backend.models.job import JobCreate


class BaseCrawler(ABC):
    source: str

    @abstractmethod
    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        ...

    def make_id(self, raw_id: str | int) -> str:
        return f"{self.source}_{raw_id}"

    async def _sleep(self):
        """Random sleep 1-3s between requests to avoid rate limiting."""
        await asyncio.sleep(random.uniform(1.0, 3.0))
```

- [ ] **Step 4: 實作 CakeResumeCrawler**

```python
# backend/crawlers/crawler_cake.py
import httpx
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    )
}


class CakeResumeCrawler(BaseCrawler):
    source = "cake"
    _base_url = "https://www.cakeresume.com/api/jobs"

    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        results: list[JobCreate] = []
        async with httpx.AsyncClient(headers=HEADERS, timeout=15) as client:
            for page in range(1, pages + 1):
                try:
                    resp = await client.get(
                        self._base_url,
                        params={"q": keyword, "page": page, "per_page": 30},
                    )
                    resp.raise_for_status()
                    data = resp.json().get("data", [])
                    for item in data:
                        results.append(self._parse(item))
                    if not data:
                        break
                    if page < pages:
                        await self._sleep()
                except httpx.HTTPError:
                    break   # graceful degradation
        return results

    def _parse(self, item: dict) -> JobCreate:
        return JobCreate(
            id=self.make_id(item["id"]),
            title=item.get("title", ""),
            company=item.get("company", {}).get("name", ""),
            location=item.get("location", {}).get("name", ""),
            is_remote=item.get("remote_working_enabled", False),
            salary_range=item.get("salary_string", ""),
            skills=[s["name"] for s in item.get("required_skills", [])],
            description=item.get("description", ""),
            source=self.source,
            url=item.get("url", ""),
        )
```

- [ ] **Step 5: 執行測試確認通過**

```powershell
pytest tests/test_crawler_cake.py -v
```

Expected: 2 passed

- [ ] **Step 6: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/crawlers/ backend/tests/test_crawler_cake.py
git commit -m "feat(backend): add BaseCrawler + CakeResume crawler"
```

---

## Task 6: 104 爬蟲

**Files:**
- Create: `backend/crawlers/crawler_104.py`
- Create: `backend/tests/test_crawler_104.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_crawler_104.py
import pytest
import respx
import httpx
from backend.crawlers.crawler_104 import Crawler104

MOCK_104_SEARCH = {
    "data": {
        "list": [
            {
                "jobNo": "8a8a8a8a",
                "jobName": "Flutter 工程師",
                "custName": "AppWorks Lab",
                "jobAddrNoDesc": "台北市",
                "salaryDesc": "月薪 80,000~120,000元",
                "tags": ["Flutter", "Dart", "Riverpod"],
                "link": {"job": "https://www.104.com.tw/job/8a8a8a8a"},
            }
        ]
    }
}

MOCK_104_DETAIL = {
    "data": {
        "jobDetail": {
            "jobNo": "8a8a8a8a",
            "jobName": "Flutter 工程師",
            "jobDescription": "負責開發 Flutter App。",
            "remoteWork": 1,
        }
    }
}


@pytest.mark.asyncio
@respx.mock
async def test_104_fetch_returns_jobs():
    respx.get("https://www.104.com.tw/jobs/search/api/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_104_SEARCH)
    )
    respx.get("https://www.104.com.tw/job-bank/jobs/8a8a8a8a").mock(
        return_value=httpx.Response(200, json=MOCK_104_DETAIL)
    )
    crawler = Crawler104()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "104_8a8a8a8a"
    assert jobs[0].title == "Flutter 工程師"
    assert "Flutter" in jobs[0].skills


@pytest.mark.asyncio
@respx.mock
async def test_104_fetch_handles_http_error():
    respx.get("https://www.104.com.tw/jobs/search/api/jobs").mock(
        return_value=httpx.Response(429)
    )
    crawler = Crawler104()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert jobs == []
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
pytest tests/test_crawler_104.py -v
```

Expected: `ModuleNotFoundError`

- [ ] **Step 3: 實作 Crawler104**

```python
# backend/crawlers/crawler_104.py
import httpx
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    ),
    "Referer": "https://www.104.com.tw/",
}

SEARCH_URL = "https://www.104.com.tw/jobs/search/api/jobs"
DETAIL_URL = "https://www.104.com.tw/job-bank/jobs/{job_no}"


class Crawler104(BaseCrawler):
    source = "104"

    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        results: list[JobCreate] = []
        async with httpx.AsyncClient(headers=HEADERS, timeout=15) as client:
            for page in range(1, pages + 1):
                try:
                    resp = await client.get(
                        SEARCH_URL,
                        params={"keyword": keyword, "page": page, "rows": 30},
                    )
                    resp.raise_for_status()
                    jobs_list = resp.json().get("data", {}).get("list", [])
                    for item in jobs_list:
                        detail = await self._fetch_detail(client, item["jobNo"])
                        results.append(self._parse(item, detail))
                        await self._sleep()
                    if not jobs_list:
                        break
                except httpx.HTTPError:
                    break
        return results

    async def _fetch_detail(self, client: httpx.AsyncClient, job_no: str) -> dict:
        try:
            resp = await client.get(DETAIL_URL.format(job_no=job_no))
            resp.raise_for_status()
            return resp.json().get("data", {}).get("jobDetail", {})
        except httpx.HTTPError:
            return {}

    def _parse(self, item: dict, detail: dict) -> JobCreate:
        is_remote = detail.get("remoteWork", 0) == 1
        return JobCreate(
            id=self.make_id(item["jobNo"]),
            title=item.get("jobName", ""),
            company=item.get("custName", ""),
            location=item.get("jobAddrNoDesc", ""),
            is_remote=is_remote,
            salary_range=item.get("salaryDesc", ""),
            skills=item.get("tags", []),
            description=detail.get("jobDescription", ""),
            source=self.source,
            url=item.get("link", {}).get("job", ""),
        )
```

- [ ] **Step 4: 執行測試確認通過**

```powershell
pytest tests/test_crawler_104.py -v
```

Expected: 2 passed

- [ ] **Step 5: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/crawlers/crawler_104.py backend/tests/test_crawler_104.py
git commit -m "feat(backend): add 104 job crawler"
```

---

## Task 7: Sync Router + Scheduler

**Files:**
- Create: `backend/scheduler.py`
- Modify: `backend/routers/sync.py`
- Create: `backend/tests/test_sync.py`

- [ ] **Step 1: 寫失敗測試**

```python
# backend/tests/test_sync.py
from unittest.mock import AsyncMock, patch
from datetime import datetime


def test_sync_status_initial(client):
    resp = client.get("/api/v1/sync/status")
    assert resp.status_code == 200
    data = resp.json()
    assert "lastSync" in data
    assert "status" in data


def test_trigger_sync_returns_accepted(client):
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
```

- [ ] **Step 2: 執行測試確認失敗**

```powershell
pytest tests/test_sync.py -v
```

Expected: ImportError（run_all_crawlers 不存在）

- [ ] **Step 3: 實作 scheduler.py**

```python
# backend/scheduler.py
import json
import logging
from datetime import datetime
from sqlmodel import Session, select
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from backend.database import engine
from backend.models.job import Job, JobCreate
from backend.crawlers.crawler_cake import CakeResumeCrawler
from backend.crawlers.crawler_104 import Crawler104

logger = logging.getLogger(__name__)

_last_sync: datetime | None = None
_last_sync_count: int = 0


def get_sync_status() -> dict:
    return {
        "lastSync": _last_sync.isoformat() if _last_sync else None,
        "jobsUpserted": _last_sync_count,
        "status": "idle",
    }


async def run_all_crawlers(keywords: list[str] | None = None) -> int:
    global _last_sync, _last_sync_count
    keywords = keywords or ["軟體", "工程師", "flutter", "backend"]
    crawlers = [CakeResumeCrawler(), Crawler104()]
    all_jobs: list[JobCreate] = []

    for crawler in crawlers:
        for kw in keywords:
            try:
                jobs = await crawler.fetch(keyword=kw, pages=2)
                all_jobs.extend(jobs)
            except Exception as e:
                logger.error(f"Crawler {crawler.source} failed for '{kw}': {e}")

    count = _upsert_jobs(all_jobs)
    _last_sync = datetime.utcnow()
    _last_sync_count = count
    return count


def _upsert_jobs(jobs: list[JobCreate]) -> int:
    count = 0
    with Session(engine) as session:
        for j in jobs:
            existing = session.get(Job, j.id)
            if existing:
                existing.title = j.title
                existing.description = j.description
                existing.salary_range = j.salary_range
                existing.skills = json.dumps(j.skills)
                existing.crawled_at = datetime.utcnow()
            else:
                session.add(Job(
                    id=j.id, title=j.title, company=j.company,
                    location=j.location, is_remote=j.is_remote,
                    salary_range=j.salary_range, skills=json.dumps(j.skills),
                    description=j.description, source=j.source, url=j.url,
                ))
                count += 1
        session.commit()
    return count


def create_scheduler() -> AsyncIOScheduler:
    scheduler = AsyncIOScheduler()
    scheduler.add_job(run_all_crawlers, "interval", hours=6, id="taiwan_crawl")
    return scheduler
```

- [ ] **Step 4: 更新 sync router**

```python
# backend/routers/sync.py
import asyncio
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
```

- [ ] **Step 5: 更新 main.py 啟動 scheduler**

```python
# backend/main.py
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
```

- [ ] **Step 6: 執行測試確認通過**

```powershell
pytest tests/test_sync.py -v
```

Expected: 3 passed

- [ ] **Step 7: 執行全部測試**

```powershell
pytest -v
```

Expected: All passed（test_models + test_database + test_api_jobs + test_crawler_cake + test_crawler_104 + test_sync）

- [ ] **Step 8: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/
git commit -m "feat(backend): add sync router, scheduler, and job upsert logic"
```

---

## Task 8: Smoke Test + 啟動驗證

**Files:** 無新增

- [ ] **Step 1: 啟動 FastAPI server**

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
uvicorn main:app --reload --port 8000
```

Expected: `Application startup complete.`

- [ ] **Step 2: 呼叫 health endpoint**

```powershell
Invoke-WebRequest http://localhost:8000/health | Select-Object -Expand Content
```

Expected: `{"status":"ok"}`

- [ ] **Step 3: 呼叫 GET /api/v1/jobs（DB 初始為空）**

```powershell
Invoke-WebRequest "http://localhost:8000/api/v1/jobs" | Select-Object -Expand Content
```

Expected: `{"items":[],"total":0,"page":1,"limit":20}`

- [ ] **Step 4: 手動觸發 sync（需要網路）**

```powershell
Invoke-WebRequest -Method POST http://localhost:8000/api/v1/sync | Select-Object -Expand Content
```

Expected: `{"status":"ok","jobsUpserted": N}`（N 視爬蟲結果而定）

- [ ] **Step 5: 確認職缺已寫入**

```powershell
Invoke-WebRequest "http://localhost:8000/api/v1/jobs?limit=5" | Select-Object -Expand Content
```

Expected: items 陣列中有真實職缺資料

- [ ] **Step 6: 最終 commit**

```powershell
cd C:\dev\career_pilot
git add -A
git commit -m "feat(backend): backend crawler service complete (Phase 1)"
```

---

## 驗收標準

- [ ] `pytest -v` 全部通過
- [ ] `GET /health` → `{"status":"ok"}`
- [ ] `GET /api/v1/jobs?q=flutter` → 正確篩選結果
- [ ] `POST /api/v1/sync` → 爬取真實職缺並回傳 jobsUpserted 數量
- [ ] `GET /api/v1/sync/status` → 顯示 lastSync 時間
