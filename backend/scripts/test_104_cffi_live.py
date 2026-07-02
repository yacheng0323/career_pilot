"""Quick smoke test for Crawler104Cffi."""
import asyncio
import sys
sys.path.insert(0, "C:/dev/career_pilot")

from backend.crawlers.crawler_104_cffi import Crawler104Cffi


async def main():
    crawler = Crawler104Cffi()
    print("Fetching 1 page from 1 category (軟體工程師)...")
    jobs = await crawler.fetch(pages=1)
    print(f"Total jobs: {len(jobs)}")
    for j in jobs[:5]:
        print(f"  [{j.source}] {j.title[:30]} | {j.company[:20]} | {j.location} | {j.salary_range}")

asyncio.run(main())
