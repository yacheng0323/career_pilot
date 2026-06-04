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
