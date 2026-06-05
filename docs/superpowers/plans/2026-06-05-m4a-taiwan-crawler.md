# M4a — Yourator Taiwan Crawler Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 新增 Yourator 台灣職缺爬蟲（httpx），讓 DB 中出現真實中文職缺資料。

**Architecture:** `CrawlerYourator` 繼承 `BaseCrawler`，呼叫 `api/v4/jobs?page=N`，多頁抓取後 upsert 到 DB。Scheduler 加入此爬蟲。

**Tech Stack:** Python, httpx（已有）, respx（測試 mock，已有）

**Branch:** `feature/m4a-taiwan-crawler`

---

## File Structure

```
backend/
├── crawlers/
│   └── crawler_yourator.py         # NEW
├── scheduler.py                    # MODIFY — 加入 CrawlerYourator
├── tests/
│   └── test_crawler_yourator.py    # NEW
```

---

## Task 1: CrawlerYourator（TDD）

**Files:**
- Create: `backend/crawlers/crawler_yourator.py`
- Create: `backend/tests/test_crawler_yourator.py`

- [ ] **Step 1: 寫失敗測試**

建立 `C:\dev\career_pilot\backend\tests\test_crawler_yourator.py`：

```python
import pytest
import respx
import httpx
from backend.crawlers.crawler_yourator import CrawlerYourator

MOCK_YOURATOR_PAGE1 = {
    "payload": {
        "hasMore": True,
        "currentPage": 1,
        "nextPage": 2,
        "jobs": [
            {
                "id": 12345,
                "name": "Flutter 工程師",
                "path": "/companies/acme/jobs/12345",
                "salary": "月薪 70,000 - 100,000",
                "lastActiveAt": "三天內更新",
                "location": "台北市",
                "companyId": 100,
                "tags": ["Flutter", "Dart", "Firebase"],
                "company": {
                    "id": 100,
                    "path": "/companies/acme",
                    "brand": "Acme 科技",
                    "enName": "acme",
                    "logo": "https://example.com/logo.png",
                    "badges": ["verified"],
                    "bannerUrl": "",
                    "canThirdPartyUrl": False,
                },
                "thirdPartyUrl": None,
                "externalSource": None,
            }
        ],
    }
}

MOCK_YOURATOR_EMPTY = {
    "payload": {
        "hasMore": False,
        "currentPage": 2,
        "nextPage": None,
        "jobs": [],
    }
}


@pytest.mark.asyncio
@respx.mock
async def test_yourator_fetch_returns_jobs():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_YOURATOR_PAGE1)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "yourator_12345"
    assert jobs[0].title == "Flutter 工程師"
    assert jobs[0].company == "Acme 科技"
    assert jobs[0].location == "台北市"
    assert jobs[0].salary_range == "月薪 70,000 - 100,000"
    assert "Flutter" in jobs[0].skills
    assert jobs[0].source == "yourator"
    assert jobs[0].url == "https://www.yourator.co/companies/acme/jobs/12345"


@pytest.mark.asyncio
@respx.mock
async def test_yourator_stops_on_empty_page():
    # Page 1 returns jobs, page 2 returns empty
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        side_effect=[
            httpx.Response(200, json=MOCK_YOURATOR_PAGE1),
            httpx.Response(200, json=MOCK_YOURATOR_EMPTY),
        ]
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=3)  # Request 3 pages, should stop at 2
    assert len(jobs) == 1  # Only page 1 had jobs


@pytest.mark.asyncio
@respx.mock
async def test_yourator_handles_http_error():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(503)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)
    assert jobs == []  # Graceful degradation
```

- [ ] **Step 2: 執行確認失敗**

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest tests/test_crawler_yourator.py -v 2>&1 | Select-Object -Last 5
```

Expected: `ModuleNotFoundError`

- [ ] **Step 3: 實作 CrawlerYourator**

建立 `C:\dev\career_pilot\backend\crawlers\crawler_yourator.py`：

```python
"""
Yourator.co — Taiwan tech job board.
Public API: GET https://www.yourator.co/api/v4/jobs?page=N&per_page=20
"""
import httpx
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

_BASE_URL = "https://www.yourator.co"
_JOBS_URL = f"{_BASE_URL}/api/v4/jobs"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json",
    "Referer": f"{_BASE_URL}/jobs",
}


class CrawlerYourator(BaseCrawler):
    source = "yourator"

    async def fetch(self, keyword: str = "", pages: int = 5) -> list[JobCreate]:
        """
        Fetch all tech jobs from Yourator (up to `pages` pages × 20 jobs).
        keyword is ignored — filtering is handled at the API query layer.
        """
        results: list[JobCreate] = []
        async with httpx.AsyncClient(headers=HEADERS, timeout=20) as client:
            for page in range(1, pages + 1):
                try:
                    resp = await client.get(
                        _JOBS_URL,
                        params={"page": page, "per_page": 20},
                    )
                    resp.raise_for_status()
                    payload = resp.json().get("payload", {})
                    jobs = payload.get("jobs", [])

                    for item in jobs:
                        results.append(self._parse(item))

                    # Stop early if no more pages
                    if not payload.get("hasMore", False) or not jobs:
                        break

                    if page < pages:
                        await self._sleep()

                except (httpx.HTTPError, Exception):
                    break  # Graceful degradation

        return results

    def _parse(self, item: dict) -> JobCreate:
        job_path = item.get("path", "")
        return JobCreate(
            id=self.make_id(item.get("id", "")),
            title=item.get("name", ""),
            company=item.get("company", {}).get("brand", ""),
            location=item.get("location", ""),
            is_remote=False,   # Yourator is primarily Taiwan on-site
            salary_range=item.get("salary", "") or "",
            skills=item.get("tags", [])[:10],
            description=item.get("name", ""),  # Full desc requires detail API
            source=self.source,
            url=f"{_BASE_URL}{job_path}" if job_path else "",
        )
```

- [ ] **Step 4: 執行測試確認通過**

```powershell
pytest tests/test_crawler_yourator.py -v 2>&1 | Select-Object -Last 8
```

Expected: 3 passed

- [ ] **Step 5: 執行全部後端測試**

```powershell
pytest -v 2>&1 | Select-Object -Last 5
```

Expected: All passed（23+ tests）

- [ ] **Step 6: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/crawlers/crawler_yourator.py backend/tests/test_crawler_yourator.py
git commit -m "feat(m4a): add Yourator Taiwan job crawler"
```

---

## Task 2: Scheduler 整合 + 驗收

**Files:**
- Modify: `backend/scheduler.py`

- [ ] **Step 1: 更新 scheduler.py 加入 Yourator**

讀取 `C:\dev\career_pilot\backend\scheduler.py`，在 import 區加入：
```python
from backend.crawlers.crawler_yourator import CrawlerYourator
```

找到 `run_all_crawlers` 中的 crawlers list：
```python
    crawlers = [RemotiveCrawler(), ArbeitnowCrawler()]
```
替換為：
```python
    crawlers = [RemotiveCrawler(), ArbeitnowCrawler(), CrawlerYourator()]
```

- [ ] **Step 2: 執行全部後端測試**

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest -v 2>&1 | Select-Object -Last 5
```

Expected: All passed

- [ ] **Step 3: 手動驗收 — 觸發 sync 並確認中文職缺入庫**

確認後端有在執行（`.\dev.ps1 -BackendOnly` 或手動 uvicorn），然後：

```powershell
# 觸發 sync
$r = Invoke-WebRequest -Method POST "http://localhost:8000/api/v1/sync" -TimeoutSec 120 -UseBasicParsing
Write-Host $r.Content

# 查詢 Yourator 職缺
$q = Invoke-WebRequest "http://localhost:8000/api/v1/jobs?source=yourator&limit=3" -UseBasicParsing
$data = $q.Content | ConvertFrom-Json
Write-Host "Yourator jobs: $($data.total)"
if ($data.items.Count -gt 0) {
    Write-Host "Sample: $($data.items[0].title) @ $($data.items[0].company)"
}
```

Expected:
- `jobsUpserted` > 0
- `source=yourator` 查到中文職缺
- title 和 company 為繁體中文

- [ ] **Step 4: Commit**

```powershell
cd C:\dev\career_pilot
git add backend/scheduler.py
git commit -m "feat(m4a): add Yourator to scheduler crawlers"
```

- [ ] **Step 5: 更新 CLAUDE.md M4a 狀態**

把 `CLAUDE.md` 中 `crawler_yourator.py` 的 🔲 改為 ✅。

- [ ] **Step 6: Commit docs**

```powershell
git add CLAUDE.md docs/superpowers/specs/2026-06-05-m4a-taiwan-crawler-design.md
git commit -m "docs(m4a): Taiwan crawler research + Yourator API spec"
```

- [ ] **Step 7: merge feature → dev**

```powershell
git checkout dev
git merge --no-ff feature/m4a-taiwan-crawler -m "feat(m4a): Yourator Taiwan crawler complete"
git checkout feature/m4a-taiwan-crawler
```

---

## 驗收標準

- [ ] `pytest -v` 全部通過（23+ tests）
- [ ] `POST /api/v1/sync` → DB 中有 `source=yourator` 的職缺
- [ ] 職缺的 `title`、`company`、`location` 為繁體中文
- [ ] `dart analyze lib/` zero errors（後端改動不影響 Flutter）
