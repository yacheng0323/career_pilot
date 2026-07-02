"""Probe scripts for remaining tech debt (2026-07-02):
1. 104 job detail API — does it expose real skills (condition.specialty)?
2. Yourator job detail API — full description shape?
3. 1111.com.tw — any usable JSON search API?

Run once manually; results feed the research doc. Not production code.
"""
import asyncio
import json

import httpx
from curl_cffi import requests as cffi_requests

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")


def probe_104_detail():
    print("=" * 60)
    print("[1] 104 detail API")
    # First get one jobNo from the search API
    r = cffi_requests.get(
        "https://www.104.com.tw/jobs/search/api/jobs",
        params={"jobcat": "2007001000", "page": "1", "rows": "5", "order": "11"},
        headers={"User-Agent": UA, "Referer": "https://www.104.com.tw/"},
        impersonate="chrome124", timeout=20,
    )
    print("search status:", r.status_code)
    jobs = r.json().get("data", [])
    if not jobs:
        print("no jobs from search"); return
    job_no = str(jobs[0].get("jobNo"))
    print("probing jobNo:", job_no)

    d = cffi_requests.get(
        f"https://www.104.com.tw/job/ajax/content/{job_no}",
        headers={"User-Agent": UA,
                 "Referer": f"https://www.104.com.tw/job/{job_no}"},
        impersonate="chrome124", timeout=20,
    )
    print("detail status:", d.status_code)
    if d.status_code == 200:
        data = d.json().get("data", {})
        cond = data.get("condition", {})
        print("condition keys:", list(cond.keys()))
        print("specialty:", json.dumps(cond.get("specialty", []),
                                       ensure_ascii=False)[:500])
        print("skill:", json.dumps(cond.get("skill", []),
                                   ensure_ascii=False)[:500])
    else:
        print("body head:", d.text[:300])


async def probe_yourator_detail():
    print("=" * 60)
    print("[2] Yourator detail API")
    async with httpx.AsyncClient(headers={
        "User-Agent": UA, "Referer": "https://www.yourator.co/jobs",
    }, timeout=20) as client:
        r = await client.get(
            "https://www.yourator.co/api/v4/jobs",
            params={"page": 1, "per_page": 3})
        print("list status:", r.status_code)
        jobs = r.json().get("payload", {}).get("jobs", [])
        if not jobs:
            print("no jobs"); return
        jid = jobs[0]["id"]
        path = jobs[0].get("path", "")
        print("probing id:", jid, "path:", path)
        for url in (f"https://www.yourator.co/api/v4/jobs/{jid}",
                    f"https://www.yourator.co/api/v4{path}"):
            d = await client.get(url)
            print(url, "->", d.status_code)
            if d.status_code == 200:
                body = d.json()
                pj = body.get("payload", body)
                job = pj.get("job", pj)
                print("keys:", list(job.keys())[:25])
                for k in ("description", "description_section",
                          "requirement", "requirement_section", "content"):
                    if k in job:
                        print(f"  {k}:", str(job[k])[:200])
                break


def probe_1111():
    print("=" * 60)
    print("[3] 1111 search API candidates")
    candidates = [
        ("https://www.1111.com.tw/api/v1/search/jobs",
         {"keyword": "python", "page": 1}),
        ("https://www.1111.com.tw/api/job/search",
         {"keyword": "python", "page": 1}),
        ("https://www.1111.com.tw/search/job",
         {"ks": "python", "page": 1, "fmt": "json"}),
    ]
    for url, params in candidates:
        try:
            r = cffi_requests.get(
                url, params=params,
                headers={"User-Agent": UA,
                         "Referer": "https://www.1111.com.tw/"},
                impersonate="chrome124", timeout=15,
            )
            ct = r.headers.get("content-type", "")
            print(url, "->", r.status_code, ct)
            if "json" in ct:
                print("  body head:", r.text[:300])
        except Exception as e:
            print(url, "-> EXC", type(e).__name__, str(e)[:120])


if __name__ == "__main__":
    probe_104_detail()
    asyncio.run(probe_yourator_detail())
    probe_1111()
