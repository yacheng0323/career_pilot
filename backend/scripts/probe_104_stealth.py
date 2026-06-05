"""Test 104 with playwright-stealth to bypass bot detection."""
import asyncio
from playwright.async_api import async_playwright

try:
    from playwright_stealth import stealth_async
    HAS_STEALTH = True
except ImportError:
    HAS_STEALTH = False
    print("playwright-stealth not installed")


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=["--disable-blink-features=AutomationControlled"],
        )
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

        if HAS_STEALTH:
            await stealth_async(page)
            print("Stealth mode enabled")

        # Remove webdriver flag
        await page.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
            Object.defineProperty(navigator, 'plugins', {get: () => [1,2,3]});
        """)

        # Intercept job API calls
        captured = []
        async def on_resp(response):
            url = response.url
            ct = response.headers.get("content-type", "")
            if "json" in ct and "104" in url and "static" not in url and "aidma" not in url:
                try:
                    body = await response.json()
                    if isinstance(body, dict):
                        captured.append({"url": url[:100], "keys": list(body.keys())[:6], "body": str(body)[:200]})
                except:
                    pass

        page.on("response", on_resp)

        url = "https://www.104.com.tw/jobs/search/?keyword=%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B%E5%B8%AB&order=11"
        print(f"Loading: {url}")
        await page.goto(url, timeout=30000)
        await page.wait_for_timeout(12000)

        # Check result count
        count_text = await page.evaluate("""() => {
            const el = document.querySelector('.b-pager__page, [class*="total"], [class*="count"]');
            return el ? el.innerText.trim() : 'not found';
        }""")
        print(f"Result count indicator: {count_text}")

        # Check if job cards exist
        has_jobs = await page.evaluate("""() => {
            return document.querySelectorAll('[data-job-no], article').length;
        }""")
        print(f"Job elements in DOM: {has_jobs}")

        print(f"\nCaptured JSON responses:")
        for c in captured:
            print(f"  {c['url']}")
            print(f"  keys={c['keys']}")
            print(f"  {c['body'][:150]}")

        await page.screenshot(path="scripts/104_stealth.png")
        await browser.close()


asyncio.run(main())
