"""Wait 15s for 104 SPA to fully render, then check job cards."""
import asyncio, re
from playwright.async_api import async_playwright


async def main():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0",
            locale="zh-TW",
            viewport={"width": 1280, "height": 900},
        )
        page = await ctx.new_page()

        # 軟體工程師 without area, sort by latest
        await page.goto(
            "https://www.104.com.tw/jobs/search/?keyword=%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B%E5%B8%AB&order=15&page=1",
            timeout=30000,
        )
        print("Waiting 15s for SPA to render...")
        await page.wait_for_timeout(15000)

        # Screenshot
        await page.screenshot(path="scripts/104_soft_eng.png", full_page=False)

        # Check all possible job selectors
        result = await page.evaluate("""() => {
            const checks = {};
            const selectors = [
                'article', 'article[data-job-no]', '.b-block--top-bord',
                '[class*="job-list"]', '[class*="joblist"]',
                '.tool-card', '[data-job-no]',
                'li.search-result__item', '.search-result',
            ];
            selectors.forEach(s => {
                const els = document.querySelectorAll(s);
                if (els.length) checks[s] = els.length;
            });

            // Get all data-* attributes
            const dataAttrs = new Set();
            document.querySelectorAll('[data-job-no], [data-jobno], [data-jobid]').forEach(el => {
                Object.keys(el.dataset).forEach(k => dataAttrs.add(k + '=' + el.dataset[k].substring(0,20)));
            });

            // Total count indicator
            const totalEl = document.querySelector('[class*="total"], .b-pager__page, [class*="count"]');

            return {
                checks,
                dataAttrs: Array.from(dataAttrs).slice(0, 10),
                totalText: totalEl ? totalEl.innerText.trim() : 'not found',
                bodyHasJobs: document.body.innerHTML.includes('data-job-no'),
            };
        }""")
        print(f"Total text: {result['totalText']}")
        print(f"Has data-job-no in HTML: {result['bodyHasJobs']}")
        print(f"Selectors found: {result['checks']}")
        print(f"Data attributes: {result['dataAttrs']}")

        await browser.close()


asyncio.run(main())
