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
