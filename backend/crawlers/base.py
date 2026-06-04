import asyncio
import random
from abc import ABC, abstractmethod
from backend.models.job import JobCreate


class BaseCrawler(ABC):
    source: str

    @abstractmethod
    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        ...

    def make_id(self, raw_id: str | int) -> str:
        return f"{self.source}_{raw_id}"

    async def _sleep(self):
        """Random sleep 1-3s between requests to avoid rate limiting."""
        await asyncio.sleep(random.uniform(1.0, 3.0))
