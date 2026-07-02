"""Tests for Crawler1111 — mocks curl_cffi at session level (same style as
test_crawler_104_cffi.py)."""
import pytest
from unittest.mock import patch, MagicMock

from backend.crawlers.crawler_1111 import Crawler1111

_MOCK_RESPONSE = {
    "result": {
        "pagination": {"page": 1, "limit": 30, "totalCount": 2, "totalPage": 1},
        "hits": [
            {
                "jobId": 113021067,
                "title": "(兼職工讀) <em>Python</em> 課程助教",
                "companyName": "示例科技股份有限公司",
                "description": "協助<em>Python</em>程式課程帶課。",
                "salary": "時薪 650元以上",
                "workCity": {"id": 100509, "name": "桃園市八德區"},
                "updateAt": "2026/07/02 00:10:00",
                "jobType": 4,
            },
            {
                "jobId": 113021068,
                "title": "後端工程師",
                "companyName": "遠端公司",
                "description": "打造 API。",
                "salary": "面議",
                "workCity": {"id": 1, "name": "台北市"},
                "updateAt": "2026/07/02 00:10:00",
                "jobType": 1,
            },
        ],
    }
}

_MOCK_EMPTY = {
    "result": {
        "pagination": {"page": 1, "limit": 30, "totalCount": 0, "totalPage": 0},
        "hits": [],
    }
}


def _make_mock_response(json_data, status=200):
    mock = MagicMock()
    mock.status_code = status
    mock.json.return_value = json_data
    return mock


@pytest.mark.asyncio
async def test_1111_fetch_returns_jobs():
    with patch("backend.crawlers.crawler_1111.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE)
        crawler = Crawler1111()
        jobs = await crawler.fetch(pages=1)

    assert len(jobs) == 2
    j = jobs[0]
    assert j.id == "1111_113021067"
    assert j.company == "示例科技股份有限公司"
    assert j.location == "桃園市八德區"
    assert j.salary_range == "時薪 650元以上"
    assert j.source == "1111"
    assert j.url == "https://www.1111.com.tw/job/113021067"


@pytest.mark.asyncio
async def test_1111_strips_em_highlight_tags():
    with patch("backend.crawlers.crawler_1111.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE)
        crawler = Crawler1111()
        jobs = await crawler.fetch(pages=1)

    assert "<em>" not in jobs[0].title
    assert "Python" in jobs[0].title
    assert "<em>" not in jobs[0].description


@pytest.mark.asyncio
async def test_1111_dedups_across_keywords():
    """Same job returned for multiple keywords must appear once."""
    with patch("backend.crawlers.crawler_1111.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE)
        crawler = Crawler1111()
        jobs = await crawler.fetch(pages=2)

    assert len(jobs) == 2


@pytest.mark.asyncio
async def test_1111_stops_on_empty_result():
    with patch("backend.crawlers.crawler_1111.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_EMPTY)
        crawler = Crawler1111()
        jobs = await crawler.fetch(pages=3)

    assert jobs == []


@pytest.mark.asyncio
async def test_1111_handles_http_error():
    with patch("backend.crawlers.crawler_1111.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response({}, status=403)
        crawler = Crawler1111()
        jobs = await crawler.fetch(pages=1)

    assert jobs == []
