"""
Yourator.co — Taiwan tech job board.
Public API: GET https://www.yourator.co/api/v4/jobs?page=N&per_page=20

No public detail API (api/v4/jobs/{id} → 404). Full description lives in
the job page's embedded JSON-LD JobPosting block.
"""
import asyncio
import html as html_lib
import json
import random
import re

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

    async def fetch(
        self, keyword: str = "", pages: int = 5, max_details: int = 40,
    ) -> list[JobCreate]:
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

            await self._enrich_descriptions(client, results[:max_details])

        return results

    async def _enrich_descriptions(
        self, client: httpx.AsyncClient, jobs: list[JobCreate],
    ) -> None:
        """Fill job.description from the job page's JSON-LD block."""
        for job in jobs:
            if not job.url:
                continue
            try:
                resp = await client.get(job.url)
                resp.raise_for_status()
                description = _extract_jsonld_description(resp.text)
                if description:
                    job.description = description
                await asyncio.sleep(random.uniform(0.3, 0.8))
            except Exception:
                continue  # description stays "" — upsert keeps old value

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
            # Empty placeholder — real description comes from detail
            # enrichment; upsert preserves previously enriched values.
            description="",
            source=self.source,
            url=f"{_BASE_URL}{job_path}" if job_path else "",
        )


def _extract_jsonld_description(page_html: str) -> str:
    """Pull the JobPosting description out of embedded JSON-LD, strip HTML."""
    for m in re.finditer(
        r'<script type="application/ld\+json">(.*?)</script>',
        page_html, re.S,
    ):
        try:
            obj = json.loads(m.group(1))
        except json.JSONDecodeError:
            continue
        if obj.get("@type") != "JobPosting":
            continue
        raw = obj.get("description", "")
        text = re.sub(r"<[^>]+>", " ", raw)
        text = html_lib.unescape(text)
        text = re.sub(r"\s+", " ", text).strip()
        return text[:1000]
    return ""
