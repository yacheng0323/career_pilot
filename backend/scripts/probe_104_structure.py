"""Get full 104 job item structure."""
from curl_cffi import requests as cffi_requests

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0",
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "zh-TW,zh;q=0.9",
    "Referer": "https://www.104.com.tw/",
}


def main():
    r = cffi_requests.get(
        "https://www.104.com.tw/jobs/search/api/jobs",
        params={"keyword": "工程師", "page": "1", "rows": "3", "order": "11"},
        headers=HEADERS,
        impersonate="chrome124",
        timeout=15,
    )
    data = r.json()
    jobs = data["data"]  # list directly
    metadata = data.get("metadata", {})

    print(f"Total results: {metadata.get('total', '?')}")
    print(f"Jobs this page: {len(jobs)}")
    print()

    j = jobs[0]
    print("=== All keys on first job ===")
    for k, v in j.items():
        val_str = str(v)[:60] if not isinstance(v, (dict, list)) else f"{type(v).__name__}({len(v)})"
        print(f"  {k}: {val_str}")

    print("\n=== Key fields for crawler ===")
    print(f"  jobNo: {j.get('jobNo', '?')}")
    print(f"  jobName: {j.get('jobName', '?')}")
    print(f"  custName: {j.get('custName', '?')}")
    print(f"  jobAddrNoDesc: {j.get('jobAddrNoDesc', '?')}")
    print(f"  salaryDesc: {j.get('salaryDesc', '?')}")
    print(f"  tags: {j.get('tags', [])}")
    print(f"  description: {j.get('descSnippet', j.get('description', ''))[:100]}")
    print(f"  link: {j.get('link', {})}")
    print(f"  remoteWork: {j.get('remoteWork', '?')}")
    print(f"  appearDate: {j.get('appearDate', '?')}")

    # Test pagination - metadata
    print(f"\n=== Metadata ===")
    for k, v in metadata.items():
        print(f"  {k}: {v}")


main()
