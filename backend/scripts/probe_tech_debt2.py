"""Round 2 probes: 104 detail via URL slug, Yourator page-embedded JSON,
1111 full hit shape."""
import asyncio
import json
import re

import httpx
from curl_cffi import requests as cffi_requests

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")


def probe_104_detail_slug():
    print("=" * 60)
    print("[1] 104 detail via slug from link.job")
    r = cffi_requests.get(
        "https://www.104.com.tw/jobs/search/api/jobs",
        params={"jobcat": "2007001000", "page": "1", "rows": "5", "order": "11"},
        headers={"User-Agent": UA, "Referer": "https://www.104.com.tw/"},
        impersonate="chrome124", timeout=20,
    )
    jobs = r.json().get("data", [])
    if not jobs:
        print("no jobs"); return
    link = jobs[0].get("link", {}).get("job", "")
    print("link.job:", link)
    m = re.search(r"/job/([0-9a-z]+)", link)
    if not m:
        print("no slug"); return
    slug = m.group(1)
    d = cffi_requests.get(
        f"https://www.104.com.tw/job/ajax/content/{slug}",
        headers={"User-Agent": UA,
                 "Referer": f"https://www.104.com.tw/job/{slug}"},
        impersonate="chrome124", timeout=20,
    )
    print("detail status:", d.status_code)
    if d.status_code == 200:
        data = d.json().get("data", {})
        cond = data.get("condition", {})
        print("condition keys:", list(cond.keys()))
        print("specialty:", json.dumps(cond.get("specialty", []),
                                       ensure_ascii=False)[:600])
        print("skill:", json.dumps(cond.get("skill", []),
                                   ensure_ascii=False)[:600])


async def probe_yourator_page_json():
    print("=" * 60)
    print("[2] Yourator job page embedded JSON")
    async with httpx.AsyncClient(headers={"User-Agent": UA}, timeout=20,
                                 follow_redirects=True) as client:
        r = await client.get("https://www.yourator.co/api/v4/jobs",
                             params={"page": 1, "per_page": 3})
        jobs = r.json().get("payload", {}).get("jobs", [])
        if not jobs:
            print("no jobs"); return
        path = jobs[0]["path"]
        page = await client.get(f"https://www.yourator.co{path}")
        print("page status:", page.status_code, "len:", len(page.text))
        # JSON-LD?
        for m in re.finditer(
                r'<script type="application/ld\+json">(.*?)</script>',
                page.text, re.S):
            try:
                obj = json.loads(m.group(1))
                t = obj.get("@type")
                print("json-ld @type:", t)
                if t == "JobPosting":
                    desc = obj.get("description", "")
                    print("  description len:", len(desc))
                    print("  head:", re.sub(r"<[^>]+>", " ", desc)[:300])
            except Exception as e:
                print("json-ld parse fail:", e)


def probe_1111_shape():
    print("=" * 60)
    print("[3] 1111 hit shape")
    r = cffi_requests.get(
        "https://www.1111.com.tw/api/v1/search/jobs",
        params={"keyword": "python", "page": 1},
        headers={"User-Agent": UA, "Referer": "https://www.1111.com.tw/"},
        impersonate="chrome124", timeout=20,
    )
    result = r.json().get("result", {})
    hits = result.get("hits", [])
    print("totalCount:", result.get("pagination", {}).get("totalCount"))
    if hits:
        h = hits[0]
        print("hit keys:", sorted(h.keys()))
        print(json.dumps(h, ensure_ascii=False, indent=1)[:2500])


if __name__ == "__main__":
    probe_104_detail_slug()
    asyncio.run(probe_yourator_page_json())
    probe_1111_shape()
