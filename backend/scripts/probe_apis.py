"""
Confirmed:
- Yourator: https://www.yourator.co/api/v4/jobs?page=1
- 104: Need to probe deeper
"""
import asyncio
from playwright.async_api import async_playwright


async def test_yourator_api():
    """Test the Yourator API endpoint directly."""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0",
            locale="zh-TW",
        )
        page = await ctx.new_page()

        # First visit the site to get cookies
        await page.goto("https://www.yourator.co/jobs", timeout=30000)
        await page.wait_for_timeout(2000)

        # Now call the API directly
        response = await page.evaluate("""async () => {
            const r = await fetch('https://www.yourator.co/api/v4/jobs?page=1', {
                headers: {'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest'}
            });
            const data = await r.json();
            return JSON.stringify(data).substring(0, 800);
        }""")

        print("\n=== Yourator API v4/jobs ===")
        print(response)
        await browser.close()


async def test_104_search():
    """Try to get 104 search API by using Playwright with proper session."""
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/124.0",
            locale="zh-TW",
            extra_http_headers={"Referer": "https://www.104.com.tw/"},
        )
        page = await ctx.new_page()
        captured = []

        async def on_response(response):
            url = response.url
            ct = response.headers.get("content-type", "")
            if "json" in ct and "104" in url and "aidma" not in url and "static" not in url:
                try:
                    body = await response.json()
                    captured.append({"url": url[:120], "body": str(body)[:200]})
                except Exception:
                    pass

        page.on("response", on_response)

        # Visit 104 search and wait for job cards
        await page.goto(
            "https://www.104.com.tw/jobs/search/?keyword=flutter&area=6001001000&order=11",
            timeout=30000,
        )
        await page.wait_for_timeout(8000)

        print("\n=== 104 JSON APIs (non-static) ===")
        for c in captured:
            print(f"  {c['url']}")
            print(f"    {c['body'][:150]}")

        # Also try calling their known API with browser context
        result = await page.evaluate("""async () => {
            try {
                const r = await fetch(
                    'https://www.104.com.tw/jobs/search/api/jobs?keyword=flutter&area=6001001000&rows=5&page=1&order=11',
                    {credentials: 'include', headers: {'Referer': 'https://www.104.com.tw/'}}
                );
                const data = await r.json();
                return JSON.stringify({status: r.status, keys: Object.keys(data)});
            } catch(e) { return 'ERROR: ' + e.message; }
        }""")
        print(f"\n  Direct API call result: {result}")

        await browser.close()


asyncio.run(test_yourator_api())
asyncio.run(test_104_search())
