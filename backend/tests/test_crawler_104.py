import pytest
import respx
import httpx
from backend.crawlers.crawler_104 import Crawler104

MOCK_104_SEARCH = {
    "data": {
        "list": [
            {
                "jobNo": "8a8a8a8a",
                "jobName": "Flutter 工程師",
                "custName": "AppWorks Lab",
                "jobAddrNoDesc": "台北市",
                "salaryDesc": "月薪 80,000~120,000元",
                "tags": ["Flutter", "Dart", "Riverpod"],
                "link": {"job": "https://www.104.com.tw/job/8a8a8a8a"},
            }
        ]
    }
}

MOCK_104_DETAIL = {
    "data": {
        "jobDetail": {
            "jobNo": "8a8a8a8a",
            "jobName": "Flutter 工程師",
            "jobDescription": "負責開發 Flutter App。",
            "remoteWork": 1,
        }
    }
}


@pytest.mark.asyncio
@respx.mock
async def test_104_fetch_returns_jobs():
    respx.get("https://www.104.com.tw/jobs/search/api/jobs").mock(
        return_value=httpx.Response(200, json=MOCK_104_SEARCH)
    )
    respx.get("https://www.104.com.tw/job-bank/jobs/8a8a8a8a").mock(
        return_value=httpx.Response(200, json=MOCK_104_DETAIL)
    )
    crawler = Crawler104()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert len(jobs) == 1
    assert jobs[0].id == "104_8a8a8a8a"
    assert jobs[0].title == "Flutter 工程師"
    assert "Flutter" in jobs[0].skills


@pytest.mark.asyncio
@respx.mock
async def test_104_fetch_handles_http_error():
    respx.get("https://www.104.com.tw/jobs/search/api/jobs").mock(
        return_value=httpx.Response(429)
    )
    crawler = Crawler104()
    jobs = await crawler.fetch(keyword="flutter", pages=1)
    assert jobs == []
