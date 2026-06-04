"""
Arbeitnow — free public job board API (no auth required).
Docs: https://www.arbeitnow.com/api/job-board-api
Returns up to 100 jobs per page, cursor-based pagination.
"""
import httpx
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

HEADERS = {"User-Agent": "CareerPilot/1.0"}


class ArbeitnowCrawler(BaseCrawler):
    source = "arbeitnow"
    _base_url = "https://www.arbeitnow.com/api/job-board-api"

    async def fetch(self, keyword: str = "", pages: int = 2) -> list[JobCreate]:
        """
        Fetch all jobs from Arbeitnow (up to `pages` pages × 100 jobs).
        keyword is ignored — filtering is handled at the API query layer.
        """
        results: list[JobCreate] = []
        async with httpx.AsyncClient(headers=HEADERS, timeout=20) as client:
            for page in range(1, pages + 1):
                try:
                    resp = await client.get(
                        self._base_url,
                        params={"page": page},
                    )
                    resp.raise_for_status()
                    jobs = resp.json().get("data", [])
                    for item in jobs:
                        results.append(self._parse(item))
                    if not jobs:
                        break
                    if page < pages:
                        await self._sleep()
                except (httpx.HTTPError, Exception):
                    break
        return results

    def _parse(self, item: dict) -> JobCreate:
        tags = item.get("tags", [])
        location = item.get("location", "")
        is_remote = item.get("remote", False) or "remote" in location.lower()

        return JobCreate(
            id=self.make_id(item.get("slug", item.get("title", "")[:20])),
            title=item.get("title", ""),
            company=item.get("company_name", ""),
            location=location or ("Remote" if is_remote else ""),
            is_remote=is_remote,
            salary_range="",   # Arbeitnow doesn't expose salary in free API
            skills=tags[:10],
            description=_strip_html(item.get("description", "")),
            source=self.source,
            url=item.get("url", ""),
        )


def _strip_html(html: str) -> str:
    import re
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:1000]
