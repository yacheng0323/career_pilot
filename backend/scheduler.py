import json
import logging
from datetime import datetime
from sqlmodel import Session, select
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from backend.database import engine
from backend.models.job import Job, JobCreate
from backend.crawlers.crawler_cake import CakeResumeCrawler
from backend.crawlers.crawler_104 import Crawler104

logger = logging.getLogger(__name__)

_last_sync: datetime | None = None
_last_sync_count: int = 0


def get_sync_status() -> dict:
    return {
        "lastSync": _last_sync.isoformat() if _last_sync else None,
        "jobsUpserted": _last_sync_count,
        "status": "idle",
    }


async def run_all_crawlers(keywords: list[str] | None = None) -> int:
    global _last_sync, _last_sync_count
    keywords = keywords or ["軟體", "工程師", "flutter", "backend"]
    crawlers = [CakeResumeCrawler(), Crawler104()]
    all_jobs: list[JobCreate] = []

    for crawler in crawlers:
        for kw in keywords:
            try:
                jobs = await crawler.fetch(keyword=kw, pages=2)
                all_jobs.extend(jobs)
            except Exception as e:
                logger.error(f"Crawler {crawler.source} failed for '{kw}': {e}")

    count = _upsert_jobs(all_jobs)
    _last_sync = datetime.utcnow()
    _last_sync_count = count
    return count


def _upsert_jobs(jobs: list[JobCreate]) -> int:
    count = 0
    seen_ids: set[str] = set()
    with Session(engine) as session:
        for j in jobs:
            if j.id in seen_ids:
                continue
            seen_ids.add(j.id)
            existing = session.get(Job, j.id)
            if existing:
                existing.title = j.title
                existing.description = j.description
                existing.salary_range = j.salary_range
                existing.skills = json.dumps(j.skills)
                existing.crawled_at = datetime.utcnow()
            else:
                session.add(Job(
                    id=j.id,
                    title=j.title,
                    company=j.company,
                    location=j.location,
                    is_remote=j.is_remote,
                    salary_range=j.salary_range,
                    skills=json.dumps(j.skills),
                    description=j.description,
                    source=j.source,
                    url=j.url,
                ))
                count += 1
        session.commit()
    return count


def create_scheduler() -> AsyncIOScheduler:
    scheduler = AsyncIOScheduler()
    scheduler.add_job(run_all_crawlers, "interval", hours=6, id="taiwan_crawl")
    return scheduler
