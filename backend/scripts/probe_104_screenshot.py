"""Save 104 screenshot and check page HTML structure."""
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

        await page.goto(
            "https://www.104.com.tw/jobs/search/?keyword=flutter&area=6001001000",
            timeout=30000,
        )
        await page.wait_for_timeout(6000)

        # Screenshot
        await page.screenshot(path="scripts/104_screenshot.png", full_page=False)
        print("Screenshot saved to scripts/104_screenshot.png")

        # Get the first 3000 chars of body HTML to understand structure
        html_snippet = await page.evaluate("""() => {
            const body = document.body;
            // Get all unique tag+class combos
            const tags = new Set();
            body.querySelectorAll('*').forEach(el => {
                if (el.className && typeof el.className === 'string') {
                    const classes = el.className.split(' ').filter(c =>
                        c.includes('job') || c.includes('Job') ||
                        c.includes('card') || c.includes('Card') ||
                        c.includes('list') || c.includes('List')
                    );
                    classes.forEach(c => tags.add(el.tagName + '.' + c));
                }
            });
            return Array.from(tags).slice(0, 20).join('\\n');
        }""")
        print("Job-related selectors found:")
        print(html_snippet if html_snippet else "(none)")

        # Check if page is asking for CAPTCHA or login
        page_text = await page.inner_text("body")
        if any(w in page_text for w in ["captcha", "驗證", "登入", "CAPTCHA"]):
            print("\n!! Page requires CAPTCHA or login !!")
        else:
            print(f"\nPage text preview: {page_text[:200]}")

        await browser.close()


asyncio.run(main())
