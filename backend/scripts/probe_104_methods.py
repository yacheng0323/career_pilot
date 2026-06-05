"""
Systematically test all viable methods to access 104 job data.

Method 1: curl_cffi (Chrome TLS fingerprint impersonation)
Method 2: 104 Mobile API (app.104.com.tw)
Method 3: 104 Open API (if any)
Method 4: Playwright with proper session establishment
"""
import asyncio
import sys

# ── Method 1: curl_cffi ───────────────────────────────────────────────────────
def test_curl_cffi():
    print("\n=== Method 1: curl_cffi (Chrome TLS impersonation) ===")
    try:
        from curl_cffi import requests as cffi_requests

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "zh-TW,zh;q=0.9",
            "Referer": "https://www.104.com.tw/",
        }

        # Direct job search API
        r = cffi_requests.get(
            "https://www.104.com.tw/jobs/search/api/jobs",
            params={"keyword": "軟體工程師", "page": 1, "rows": 5, "order": 11},
            headers=headers,
            impersonate="chrome124",
            timeout=15,
        )
        print(f"  Status: {r.status_code}")
        if r.status_code == 200:
            data = r.json()
            jobs = data.get("data", {}).get("list", [])
            print(f"  Jobs: {len(jobs)}")
            if jobs:
                print(f"  Sample: {jobs[0].get('jobName', '?')}")
        else:
            print(f"  Body: {r.text[:200]}")
    except ImportError:
        print("  curl_cffi not installed")
    except Exception as e:
        print(f"  ERROR: {e}")


# ── Method 2: 104 Mobile API ──────────────────────────────────────────────────
def test_mobile_api():
    print("\n=== Method 2: 104 Mobile API ===")
    try:
        from curl_cffi import requests as cffi_requests

        # Try mobile/app API endpoints
        endpoints = [
            "https://app.104.com.tw/api/v2/jobs/search?keyword=工程師&page=1",
            "https://m.104.com.tw/jobs/search/api/jobs?keyword=工程師&page=1&rows=5",
            "https://www.104.com.tw/job/ajax/content?keyword=工程師",
        ]

        for url in endpoints:
            try:
                r = cffi_requests.get(
                    url,
                    headers={
                        "User-Agent": "104人力銀行/8.0.0 (iPhone; iOS 17.0)",
                        "Accept": "application/json",
                        "Referer": "https://www.104.com.tw/",
                    },
                    impersonate="safari17_0",
                    timeout=10,
                )
                ct = r.headers.get("content-type", "")
                print(f"  {r.status_code} [{ct[:25]}] {url[:70]}")
                if "json" in ct and r.status_code == 200:
                    data = r.json()
                    print(f"    keys: {list(data.keys())[:5]}")
            except Exception as e:
                print(f"  ERR {url[:60]}: {e}")
    except ImportError:
        print("  curl_cffi not installed, skipping")


# ── Method 3: 104 Open API ────────────────────────────────────────────────────
def test_open_api():
    print("\n=== Method 3: 104 Official/Open API ===")
    try:
        from curl_cffi import requests as cffi_requests

        # 104 has an official API for corporate clients
        # Check if any public endpoints exist
        candidates = [
            "https://api.104.com.tw/jobs?keyword=工程師",
            "https://open.104.com.tw/api/jobs?keyword=工程師",
            "https://www.104.com.tw/api/jobs?keyword=工程師",
        ]
        for url in candidates:
            try:
                r = cffi_requests.get(url, impersonate="chrome124", timeout=8)
                print(f"  {r.status_code} {url[:70]}")
            except Exception as e:
                print(f"  ERR: {e}")
    except ImportError:
        print("  curl_cffi not installed")


# ── Method 4: Playwright with 104 cookie reuse ───────────────────────────────
async def test_playwright_with_cookies():
    print("\n=== Method 4: Playwright fetch() with cookie reuse ===")
    try:
        from playwright.async_api import async_playwright

        async with async_playwright() as p:
            browser = await p.chromium.launch(
                headless=False,  # Try non-headless! 104 might not block this
                args=["--disable-blink-features=AutomationControlled"],
            )
            ctx = await browser.new_context(
                user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0",
                locale="zh-TW",
            )

            # Remove automation indicators
            page = await ctx.new_page()
            await page.add_init_script("""
                Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
                delete window.cdc_adoQpoasnfa76pfcZLmcfl_Array;
                delete window.cdc_adoQpoasnfa76pfcZLmcfl_Promise;
            """)

            # Visit 104 to establish a real session
            await page.goto("https://www.104.com.tw/", timeout=20000)
            await page.wait_for_timeout(2000)

            # Now use fetch() with established cookies to call the API
            result = await page.evaluate("""async () => {
                try {
                    const r = await fetch(
                        'https://www.104.com.tw/jobs/search/api/jobs?keyword=工程師&page=1&rows=5&order=11',
                        {
                            credentials: 'include',
                            headers: {
                                'Accept': 'application/json, text/plain, */*',
                                'Referer': 'https://www.104.com.tw/jobs/search/?keyword=%E5%B7%A5%E7%A8%8B%E5%B8%AB',
                            }
                        }
                    );
                    const ct = r.headers.get('content-type') || '';
                    if (ct.includes('json')) {
                        const data = await r.json();
                        const jobs = (data.data || {}).list || [];
                        return {status: r.status, count: jobs.length, sample: jobs[0]?.jobName || ''};
                    }
                    return {status: r.status, body: (await r.text()).substring(0, 100)};
                } catch(e) { return {error: e.message}; }
            }""")
            print(f"  Result: {result}")
            await browser.close()

    except Exception as e:
        print(f"  ERROR: {e}")


if __name__ == "__main__":
    test_curl_cffi()
    test_mobile_api()
    test_open_api()
    asyncio.run(test_playwright_with_cookies())
