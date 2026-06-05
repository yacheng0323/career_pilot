import pytest
import respx
import httpx
from backend.crawlers.crawler_yourator import CrawlerYourator

MOCK_YOURATOR_PAGE1 = {
    "payload": {
        "hasMore": True,
        "currentPage": 1,
        "nextPage": 2,
        "jobs": [
            {
                "id": 12345,
                "name": "Flutter 工程師",
                "path": "/companies/acme/jobs/12345",
                "salary": "月薪 70,000 - 100,000",
                "lastActiveAt": "三天內更新",
                "location": "台北市",
                "companyId": 100,
                "tags": ["Flutter", "Dart", "Firebase"],
                "company": {
                    "id": 100,
                    "path": "/companies/acme",
                    "brand": "Acme 科技",
                    "enName": "acme",
                    "logo": "https://example.com/logo.png",
                    "badges": ["verified"],
                    "bannerUrl": "",
                    "canThirdPartyUrl": False,
                },
                "thirdPartyUrl": None,
                "externalSource": None,
            }
        ],
    }
}

MOCK_YOURATOR_EMPTY = {
    "payload": {
        "hasMore": False,
        "currentPage": 2,
        "nextPage": None,
        "jobs": [],
    }
}


@pytest.mark.asyncio
@respx.mock
async def test_yourator_fetch_returns_jobs():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_YOURATOR_PAGE1)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "yourator_12345"
    assert jobs[0].title == "Flutter 工程師"
    assert jobs[0].company == "Acme 科技"
    assert jobs[0].location == "台北市"
    assert jobs[0].salary_range == "月薪 70,000 - 100,000"
    assert "Flutter" in jobs[0].skills
    assert jobs[0].source == "yourator"
    assert jobs[0].url == "https://www.yourator.co/companies/acme/jobs/12345"


@pytest.mark.asyncio
@respx.mock
async def test_yourator_stops_on_empty_page():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        side_effect=[
            httpx.Response(200, json=MOCK_YOURATOR_PAGE1),
            httpx.Response(200, json=MOCK_YOURATOR_EMPTY),
        ]
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=3)
    assert len(jobs) == 1


@pytest.mark.asyncio
@respx.mock
async def test_yourator_handles_http_error():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(503)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)
    assert jobs == []
