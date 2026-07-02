"""
Intercept 104's internal API calls when the SPA loads job results.
"""
import asyncio
from playwright.async_api import async_playwright


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(
            user_agent=(
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/124.0.0.0 Safari/537.36"
            ),
            locale="zh-TW",
            viewport={"width": 1280, "height": 900},
        )
        page = await ctx.new_page()
        all_json = []

        async def capture(response):
            url = response.url
            ct = response.headers.get("content-type", "")
            # Skip obvious non-job URLs
            skip = ["static.", ".js", ".css", ".png", ".jpg", "font", "analytics",
                    "aidma", "googletagmanager", "doubleclick", "fbcdn"]
            if any(s in url for s in skip):
                return
            if "json" in ct or "javascript" in ct.split(";")[0]:
                try:
                    body = await response.json()
                    if isinstance(body, dict) and any(
                        k in body for k in ["data", "list", "result", "jobs", "total"]
                    ):
                        all_json.append({
                            "url": url[:120],
                            "keys": list(body.keys())[:8],
                            "snippet": str(body)[:300],
                        })
                except Exception:
                    pass

        page.on("response", capture)

        url = "https://www.104.com.tw/jobs/search/?keyword=%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B%E5%B8%AB&order=11&page=1"
        await page.goto(url, timeout=30000)

        # Wait for Vue SPA to initialize and fetch data
        await page.wait_for_timeout(10000)

        # Try scrolling to trigger lazy loading
        await page.keyboard.press("End")
        await page.wait_for_timeout(3000)

        print(f"Captured {len(all_json)} relevant JSON responses:")
        for item in all_json:
            print(f"\n  URL: {item['url']}")
            print(f"  keys: {item['keys']}")
            print(f"  snippet: {item['snippet'][:200]}")

        # Try direct API call with session cookies
        cookies = await ctx.cookies()
        cookie_str = "; ".join(f"{c['name']}={c['value']}" for c in cookies)
        result = await page.evaluate(f"""async () => {{
            const r = await fetch(
                'https://www.104.com.tw/jobs/search/api/jobs?keyword=%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B%E5%B8%AB&page=1&rows=10&order=11',
                {{
                    credentials: 'include',
                    headers: {{
                        'Accept': 'application/json, text/plain, */*',
                        'Referer': 'https://www.104.com.tw/',
                    }}
                }}
            );
            const text = await r.text();
            return JSON.stringify({{status: r.status, body: text.substring(0, 300)}});
        }}""")
        print(f"\nDirect API call: {result}")

        await browser.close()


asyncio.run(main())
