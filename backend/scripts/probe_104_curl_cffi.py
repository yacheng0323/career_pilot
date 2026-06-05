"""
curl_cffi successfully bypassed Cloudflare on 104!
Now figure out the exact response structure and extract jobs.
"""
import json
from curl_cffi import requests as cffi_requests

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "zh-TW,zh;q=0.9,en;q=0.8",
    "Referer": "https://www.104.com.tw/",
}


def test_search_api():
    print("\n=== 104 Search API via curl_cffi ===")
    r = cffi_requests.get(
        "https://www.104.com.tw/jobs/search/api/jobs",
        params={
            "keyword": "工程師",
            "page": "1",
            "rows": "5",
            "order": "11",
            "jobcat": "2007001000",  # IT/Software category
        },
        headers=HEADERS,
        impersonate="chrome124",
        timeout=15,
    )
    print(f"Status: {r.status_code}")
    print(f"Content-Type: {r.headers.get('content-type', '')}")

    try:
        data = r.json()
        print(f"Top-level keys: {list(data.keys()) if isinstance(data, dict) else type(data)}")

        if isinstance(data, dict):
            # Try to find the job list
            for key in ["data", "list", "jobs", "result"]:
                val = data.get(key)
                if val is not None:
                    print(f"  data['{key}'] type: {type(val)}")
                    if isinstance(val, dict):
                        print(f"    sub-keys: {list(val.keys())}")
                        inner_list = val.get("list") or val.get("jobs") or []
                        if inner_list:
                            print(f"    jobs count: {len(inner_list)}")
                            j = inner_list[0]
                            print(f"    job keys: {list(j.keys())[:10]}")
                            print(f"    jobName: {j.get('jobName', '?')}")
                            print(f"    custName: {j.get('custName', '?')}")
                            print(f"    jobAddrNoDesc: {j.get('jobAddrNoDesc', '?')}")
                    elif isinstance(val, list):
                        print(f"    list length: {len(val)}")
                        if val:
                            print(f"    first item keys: {list(val[0].keys())[:10]}")
        else:
            print(f"Response is {type(data)}: {str(data)[:300]}")
    except Exception as e:
        print(f"JSON parse error: {e}")
        print(f"Raw body: {r.text[:500]}")


def test_job_detail(job_no: str = "8a8a8a8a"):
    """Test fetching a single job detail."""
    print(f"\n=== 104 Job Detail API: {job_no} ===")
    r = cffi_requests.get(
        f"https://www.104.com.tw/job-bank/jobs/{job_no}",
        headers=HEADERS,
        impersonate="chrome124",
        timeout=15,
    )
    print(f"Status: {r.status_code}")
    if r.status_code == 200:
        try:
            data = r.json()
            detail = data.get("data", {}).get("jobDetail", {})
            print(f"Description (first 200): {detail.get('jobDescription', '')[:200]}")
        except Exception as e:
            print(f"Parse error: {e}")


if __name__ == "__main__":
    test_search_api()
