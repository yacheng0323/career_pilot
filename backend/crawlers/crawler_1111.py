"""
1111.com.tw Job Crawler — curl_cffi (same TLS-fingerprint approach as 104).

API (probed 2026-07-02, see specs/2026-07-02-crawler-enrichment-research.md):
  GET https://www.1111.com.tw/api/v1/search/jobs?keyword=X&page=N

Response:
  {"result": {"pagination": {page, limit: 30, totalCount, totalPage},
              "hits": [...]}}

Hit fields used:
  jobId, title, companyName, description, salary (display string),
  workCity.name
Notes:
  - title/description wrap matched keywords in <em> tags — stripped
  - no skills field, no remote flag in the API
  - job URL: https://www.1111.com.tw/job/{jobId}
"""
import asyncio
import random
import re

from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

try:
    from curl_cffi import requests as cffi_requests
    _CFFI_AVAILABLE = True
except ImportError:
    _CFFI_AVAILABLE = False

_SEARCH_URL = "https://www.1111.com.tw/api/v1/search/jobs"
_JOB_URL = "https://www.1111.com.tw/job/"

_KEYWORDS = ["軟體工程師", "python", "前端工程師"]

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
    "Referer": "https://www.1111.com.tw/",
}


def _strip_em(text: str) -> str:
    return re.sub(r"</?em>", "", text or "")


class Crawler1111(BaseCrawler):
    source = "1111"

    async def fetch(self, keyword: str = "", pages: int = 2) -> list[JobCreate]:
        if not _CFFI_AVAILABLE:
            return []

        keywords = [keyword] if keyword else _KEYWORDS
        results: list[JobCreate] = []
        seen_ids: set[str] = set()
        loop = asyncio.get_event_loop()

        for kw in keywords:
            for page in range(1, pages + 1):
                try:
                    response = await loop.run_in_executor(
                        None,
                        lambda k=kw, p=page: cffi_requests.get(
                            _SEARCH_URL,
                            params={"keyword": k, "page": str(p)},
                            headers=_HEADERS,
                            impersonate="chrome124",
                            timeout=20,
                        ),
                    )
                    if response.status_code != 200:
                        break

                    result = response.json().get("result", {})
                    hits = result.get("hits", [])
                    total_page = (
                        result.get("pagination", {}).get("totalPage", 1)
                    )

                    for item in hits:
                        job_id = self.make_id(str(item.get("jobId", "")))
                        if job_id in seen_ids:
                            continue
                        seen_ids.add(job_id)
                        results.append(self._parse(item))

                    if not hits or page >= total_page:
                        break

                    await asyncio.sleep(random.uniform(1.0, 2.5))

                except Exception:
                    break  # graceful degradation per keyword/page

            await asyncio.sleep(random.uniform(0.5, 1.5))

        return results

    def _parse(self, item: dict) -> JobCreate:
        job_id = str(item.get("jobId", ""))
        return JobCreate(
            id=self.make_id(job_id),
            title=_strip_em(item.get("title", "")),
            company=item.get("companyName", ""),
            location=item.get("workCity", {}).get("name", "") or "",
            is_remote=False,  # API exposes no remote flag
            salary_range=item.get("salary", "") or "",
            skills=[],  # API exposes no skills field
            description=_strip_em(item.get("description", ""))[:1000],
            source=self.source,
            url=f"{_JOB_URL}{job_id}",
        )
