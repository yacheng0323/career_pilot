"""
Test Playwright DOM extraction for 104 search results.
Since 104's API is blocked by Cloudflare, we extract from the rendered HTML.
"""
import asyncio
import json
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
        )
        page = await ctx.new_page()

        print("Navigating to 104 search page...")
        await page.goto(
            "https://www.104.com.tw/jobs/search/?keyword=flutter&area=6001001000&order=11",
            timeout=30000,
        )
        await page.wait_for_timeout(5000)

        # Try to find job cards in DOM via JS
        result = await page.evaluate("""() => {
            const jobs = [];

            // Try multiple selectors
            const selectors = [
                'article[data-job-no]',
                '[data-job-no]',
                '.b-block--top-bord',
                'article',
                'li[role="listitem"]',
            ];

            let cards = [];
            for (const sel of selectors) {
                cards = document.querySelectorAll(sel);
                if (cards.length > 2) break;
            }

            cards.forEach(card => {
                const jobNo = card.getAttribute('data-job-no') || '';
                const titleEl = card.querySelector('a[data-jobno], .js-job-link, h2 a, [class*="job-name"]');
                const title = titleEl ? titleEl.innerText.trim() : '';
                const compEl = card.querySelector('[class*="company"], [data-company]');
                const company = compEl ? compEl.innerText.trim() : '';
                const locEl = card.querySelector('[class*="location"], [class*="area"]');
                const location = locEl ? locEl.innerText.trim() : '';
                if (title) {
                    jobs.push({jobNo, title, company, location});
                }
            });

            return {
                cardCount: cards.length,
                jobs: jobs.slice(0, 5),
                pageTitle: document.title.substring(0, 60),
            };
        }""")

        print(f"Page title: {result['pageTitle']}")
        print(f"Cards found: {result['cardCount']}")
        print(f"Jobs extracted: {len(result['jobs'])}")
        for j in result["jobs"]:
            print(f"  {j['title'][:40]} | {j['company'][:30]} | {j['jobNo']}")

        # Also check what scripts inject the data
        vue_data = await page.evaluate("""() => {
            // Check if Vue or window data has job list
            if (window.__NUXT__) return 'NUXT found';
            if (window.__STORE__) return JSON.stringify(Object.keys(window.__STORE__));
            if (window.jobData) return 'jobData found';
            return 'no framework data found';
        }""")
        print(f"\nFramework data: {vue_data}")

        await browser.close()


asyncio.run(main())
