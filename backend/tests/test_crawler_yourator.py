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


# ---------------------------------------------------------------------------
# JSON-LD description enrichment (2026-07-02 tech debt)
# ---------------------------------------------------------------------------
MOCK_JOB_PAGE_HTML = """<html><head>
<script type="application/ld+json">
{"@context":"https://schema.org","@type":"JobPosting",
 "title":"Flutter 工程師",
 "description":"<p>負責 Flutter App 開發</p><ul><li>三年以上經驗</li></ul>"}
</script>
</head><body>page</body></html>"""


@pytest.mark.asyncio
@respx.mock
async def test_yourator_enriches_description_from_jsonld():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        side_effect=[
            httpx.Response(200, json=MOCK_YOURATOR_PAGE1),
            httpx.Response(200, json=MOCK_YOURATOR_EMPTY),
        ]
    )
    respx.get("https://www.yourator.co/companies/acme/jobs/12345").mock(
        return_value=httpx.Response(200, text=MOCK_JOB_PAGE_HTML)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)

    assert "負責 Flutter App 開發" in jobs[0].description
    assert "三年以上經驗" in jobs[0].description
    assert "<p>" not in jobs[0].description  # HTML stripped


@pytest.mark.asyncio
@respx.mock
async def test_yourator_unenriched_description_is_empty():
    """Beyond max_details cap the description must be empty (not the job
    name) so _upsert_jobs preserves any previously enriched value."""
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_YOURATOR_PAGE1)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1, max_details=0)

    assert jobs[0].description == ""


@pytest.mark.asyncio
@respx.mock
async def test_yourator_detail_failure_keeps_empty_description():
    respx.get("https://www.yourator.co/api/v4/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_YOURATOR_PAGE1)
    )
    respx.get("https://www.yourator.co/companies/acme/jobs/12345").mock(
        return_value=httpx.Response(500)
    )
    crawler = CrawlerYourator()
    jobs = await crawler.fetch(pages=1)

    assert jobs[0].description == ""
