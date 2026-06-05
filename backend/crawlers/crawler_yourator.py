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

                    if not payload.get("hasMore", False) or not jobs:
                        break

                    if page < pages:
                        await self._sleep()

                except (httpx.HTTPError, Exception):
                    break

        return results

    def _parse(self, item: dict) -> JobCreate:
        job_path = item.get("path", "")
        return JobCreate(
            id=self.make_id(item.get("id", "")),
            title=item.get("name", ""),
            company=item.get("company", {}).get("brand", ""),
            location=item.get("location", ""),
            is_remote=False,
            salary_range=item.get("salary", "") or "",
            skills=item.get("tags", [])[:10],
            description=item.get("name", ""),
            source=self.source,
            url=f"{_BASE_URL}{job_path}" if job_path else "",
        )
