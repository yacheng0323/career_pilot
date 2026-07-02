"""Test 104 job extraction with broader keywords."""
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

        # Use broader keyword, no area filter
        url = "https://www.104.com.tw/jobs/search/?keyword=%E8%BB%9F%E9%AB%94%E5%B7%A5%E7%A8%8B%E5%B8%AB&order=11&page=1"
        print(f"URL: {url}")
        await page.goto(url, timeout=30000)
        await page.wait_for_timeout(6000)

        jobs = await page.evaluate("""() => {
            const results = [];

            // Try tool-card selector (recommended jobs at bottom)
            const toolCards = document.querySelectorAll('.tool-card');
            toolCards.forEach(card => {
                const titleEl = card.querySelector('.tool-card__title a, [class*=title] a');
                const compEl = card.querySelector('[class*=company], [class*=corp]');
                const locEl = card.querySelector('[class*=location], [class*=area]');
                const salEl = card.querySelector('[class*=salary], [class*=sal]');
                if (titleEl) {
                    results.push({
                        type: 'tool-card',
                        title: titleEl.innerText.trim().substring(0, 50),
                        company: compEl ? compEl.innerText.trim().substring(0, 30) : '',
                        location: locEl ? locEl.innerText.trim() : '',
                        salary: salEl ? salEl.innerText.trim() : '',
                        href: titleEl.href || '',
                    });
                }
            });

            // Also try main job list items
            const jobItems = document.querySelectorAll('[class*="job-list"] li, article[data-job-no]');
            jobItems.forEach(item => {
                const titleEl = item.querySelector('a[data-jobno], .js-job-link, h2 a');
                if (titleEl) {
                    results.push({
                        type: 'main-list',
                        title: titleEl.innerText.trim().substring(0, 50),
                        href: titleEl.href || '',
                    });
                }
            });

            return {
                total: document.querySelector('[class*=total], .b-pager__page')?.innerText || 'unknown',
                toolCardCount: toolCards.length,
                jobItemCount: jobItems.length,
                jobs: results.slice(0, 5),
            };
        }""")

        print(f"Total indicator: {jobs['total']}")
        print(f"Tool cards: {jobs['toolCardCount']}")
        print(f"Main list items: {jobs['jobItemCount']}")
        print("Sample jobs:")
        for j in jobs["jobs"]:
            print(f"  [{j['type']}] {j['title']}")
            if j.get("href"):
                # Extract job ID from URL
                import re
                m = re.search(r"/job/(\w+)", j["href"])
                print(f"    jobId: {m.group(1) if m else 'N/A'} | href: {j['href'][:60]}")

        await browser.close()


asyncio.run(main())
