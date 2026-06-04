import pytest
import respx
import httpx
from backend.crawlers.crawler_cake import CakeResumeCrawler


MOCK_CAKE_RESPONSE = {
    "data": [
        {
            "id": 99001,
            "title": "Flutter Engineer",
            "company": {"name": "TestCo"},
            "location": {"name": "Taipei"},
            "remote_working_enabled": True,
            "salary_string": "800K-1.2M",
            "required_skills": [{"name": "Flutter"}, {"name": "Dart"}],
            "description": "Build awesome apps.",
            "url": "https://www.cakeresume.com/jobs/flutter-engineer-99001",
        }
    ]
}


@pytest.mark.asyncio
@respx.mock
async def test_cake_fetch_returns_jobs():
    respx.get("https://www.cakeresume.com/api/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_CAKE_RESPONSE)
    )
    crawler = CakeResumeCrawler()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "cake_99001"
    assert jobs[0].title == "Flutter Engineer"
    assert jobs[0].is_remote is True
    assert "Flutter" in jobs[0].skills


@pytest.mark.asyncio
@respx.mock
async def test_cake_fetch_handles_http_error():
    respx.get("https://www.cakeresume.com/api/jobs").mock(
        return_value=httpx.Response(503)
    )
    crawler = CakeResumeCrawler()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert jobs == []   # graceful degradation
