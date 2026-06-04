"""
Remotive.com — free public remote jobs API (no auth required).
Docs: https://remotive.com/api/remote-jobs
"""
import httpx
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

HEADERS = {"User-Agent": "CareerPilot/1.0"}

CATEGORIES = [
    "software-dev",
    "data",
    "devops",
    "mobile",
]


class RemotiveCrawler(BaseCrawler):
    source = "remotive"
    _base_url = "https://remotive.com/api/remote-jobs"

    async def fetch(self, keyword: str = "", pages: int = 1) -> list[JobCreate]:
        """
        Fetch all tech-category remote jobs from Remotive.
        keyword is ignored — filtering is handled at the API query layer.
        """
        results: list[JobCreate] = []
        async with httpx.AsyncClient(headers=HEADERS, timeout=20) as client:
            for category in CATEGORIES:
                try:
                    resp = await client.get(
                        self._base_url,
                        params={"category": category, "limit": 100},
                    )
                    resp.raise_for_status()
                    jobs = resp.json().get("jobs", [])
                    for item in jobs:
                        results.append(self._parse(item))
                    await self._sleep()
                except (httpx.HTTPError, Exception):
                    continue  # graceful degradation per category
        return results

    def _parse(self, item: dict) -> JobCreate:
        tags = item.get("tags", [])
        return JobCreate(
            id=self.make_id(item.get("id", "")),
            title=item.get("title", ""),
            company=item.get("company_name", ""),
            location=item.get("candidate_required_location") or "Remote",
            is_remote=True,
            salary_range=item.get("salary", "") or "",
            skills=tags[:10],   # cap at 10 tags
            description=_strip_html(item.get("description", "")),
            source=self.source,
            url=item.get("url", ""),
        )


def _strip_html(html: str) -> str:
    """Remove HTML tags for plain-text description."""
    import re
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:1000]  # cap length
