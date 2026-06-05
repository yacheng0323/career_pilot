"""
104.com.tw Job Crawler — using curl_cffi to impersonate Chrome TLS fingerprint.

Why curl_cffi:
- 104 blocks standard httpx (Cloudflare 403)
- 104 detects Playwright headless and returns 0 results
- curl_cffi mimics Chrome's exact TLS fingerprint → returns real data

API:
  GET https://www.104.com.tw/jobs/search/api/jobs
  Params: keyword, jobcat (category), page, rows, order

Response:
  {
    "data": [...],          # list of job dicts
    "metadata": {
      "pagination": {
        "total": 120919,
        "currentPage": 1,
        "lastPage": 100,
        "count": 32         # jobs on this page
      }
    }
  }

Job fields used:
  jobNo, jobName, custName, jobAddrNoDesc, description,
  link.job, remoteWorkType (0=onsite,1=remote),
  salaryLow, salaryHigh
"""
import asyncio
import random
from backend.crawlers.base import BaseCrawler
from backend.models.job import JobCreate

try:
    from curl_cffi import requests as cffi_requests
    _CFFI_AVAILABLE = True
except ImportError:
    _CFFI_AVAILABLE = False

_SEARCH_URL = "https://www.104.com.tw/jobs/search/api/jobs"

# IT & Software job categories
_JOBCATS = [
    "2007001000",  # 軟體工程師
    "2007002000",  # 網路工程師
    "2007003000",  # 系統分析師
    "2007006000",  # 韌體/驅動工程師
]

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
    "Referer": "https://www.104.com.tw/",
}


class Crawler104Cffi(BaseCrawler):
    source = "104"

    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        """
        Fetch IT jobs from 104.com.tw across multiple job categories.
        Uses curl_cffi to bypass Cloudflare TLS fingerprint detection.
        """
        if not _CFFI_AVAILABLE:
            return []

        results: list[JobCreate] = []
        seen_ids: set[str] = set()

        for jobcat in _JOBCATS:
            for page in range(1, pages + 1):
                try:
                    # curl_cffi is sync — run in executor to keep async flow
                    response = await asyncio.get_event_loop().run_in_executor(
                        None,
                        lambda cat=jobcat, p=page: cffi_requests.get(
                            _SEARCH_URL,
                            params={
                                "jobcat": cat,
                                "page": str(p),
                                "rows": "30",
                                "order": "11",  # newest first
                                "ro": "0",       # full-time
                                "scstrict": "0",
                            },
                            headers=_HEADERS,
                            impersonate="chrome124",
                            timeout=20,
                        ),
                    )

                    if response.status_code != 200:
                        break

                    data = response.json()
                    jobs_raw = data.get("data", [])
                    pagination = data.get("metadata", {}).get("pagination", {})
                    last_page = pagination.get("lastPage", 1)

                    for item in jobs_raw:
                        job_no = str(item.get("jobNo", ""))
                        job_id = self.make_id(job_no)
                        if job_id in seen_ids:
                            continue
                        seen_ids.add(job_id)
                        results.append(self._parse(item))

                    if page >= last_page or not jobs_raw:
                        break

                    # Polite delay between pages
                    await asyncio.sleep(random.uniform(1.0, 2.5))

                except Exception:
                    break  # Graceful degradation per category/page

            # Delay between categories
            await asyncio.sleep(random.uniform(2.0, 4.0))

        return results

    def _parse(self, item: dict) -> JobCreate:
        job_no = str(item.get("jobNo", ""))
        link = item.get("link", {})
        job_url = link.get("job", "") if isinstance(link, dict) else ""

        # Salary: construct from low/high
        salary_low = item.get("salaryLow", 0)
        salary_high = item.get("salaryHigh", 0)
        if salary_high >= 9_999_999:
            salary_range = "面議"
        elif salary_low and salary_high:
            salary_range = f"{salary_low // 1000}K–{salary_high // 1000}K"
        elif salary_low:
            salary_range = f"{salary_low // 1000}K+"
        else:
            salary_range = ""

        # Remote: remoteWorkType 1=full remote, 2=hybrid
        remote_type = item.get("remoteWorkType", 0)
        is_remote = remote_type in (1, 2)

        # Description: use full description field
        description = item.get("description", "") or item.get("descSnippet", "")
        # Strip 104's highlight markers [[[ ]]]
        import re
        description = re.sub(r"\[\[\[|\]\]\]", "", description).strip()
        description = description[:1000]  # cap length

        return JobCreate(
            id=self.make_id(job_no),
            title=item.get("jobName", "").replace("[[[", "").replace("]]]", ""),
            company=item.get("custName", ""),
            location=item.get("jobAddrNoDesc", ""),
            is_remote=is_remote,
            salary_range=salary_range,
            skills=[],  # 104 tags are work-feature codes, not tech skills
            description=description,
            source=self.source,
            url=job_url,
        )
