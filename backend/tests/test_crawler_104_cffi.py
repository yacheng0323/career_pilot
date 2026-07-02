"""
Tests for Crawler104Cffi using respx + a minimal curl_cffi mock.
Since curl_cffi is sync, we mock at the session level.
"""
import pytest
from unittest.mock import patch, MagicMock
from backend.crawlers.crawler_104_cffi import Crawler104Cffi

# Minimal mock response matching 104 API structure
_MOCK_RESPONSE_JOBS = {
    "data": [
        {
            "jobNo": "8u59p01",
            "jobName": "Flutter 工程師",
            "custName": "Acme 科技",
            "jobAddrNoDesc": "台北市信義區",
            "description": "負責 Flutter App 開發與維護。",
            "descSnippet": "負責 [[[Flutter]]] App 開發與維護。",
            "link": {
                "job": "https://www.104.com.tw/job/8u59p01",
                "cust": "https://www.104.com.tw/company/acme",
                "applyAnalyze": "",
            },
            "remoteWorkType": 0,
            "salaryLow": 70000,
            "salaryHigh": 100000,
            "tags": {"wf1": {"desc": "週休二日", "param": "wf1"}},
            "appearDate": "20260604",
            "applyCnt": 5,
        },
        {
            "jobNo": "8u59p02",
            "jobName": "後端工程師（遠端）",
            "custName": "Remote Corp",
            "jobAddrNoDesc": "台北市中正區",
            "description": "負責後端 API 設計。",
            "descSnippet": "負責後端 API 設計。",
            "link": {"job": "https://www.104.com.tw/job/8u59p02", "cust": "", "applyAnalyze": ""},
            "remoteWorkType": 1,
            "salaryLow": 90000,
            "salaryHigh": 9999999,
            "tags": {},
            "appearDate": "20260604",
            "applyCnt": 2,
        },
    ],
    "metadata": {
        "pagination": {
            "total": 2,
            "currentPage": 1,
            "lastPage": 1,
            "count": 2,
        }
    },
}

_MOCK_RESPONSE_EMPTY = {
    "data": [],
    "metadata": {"pagination": {"total": 0, "currentPage": 1, "lastPage": 1, "count": 0}},
}


def _make_mock_response(json_data):
    mock = MagicMock()
    mock.status_code = 200
    mock.json.return_value = json_data
    return mock


@pytest.mark.asyncio
async def test_104_fetch_returns_jobs():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE_JOBS)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    # 2 jobs × 4 categories = 8, but dedup by id so = 2
    assert len(jobs) == 2
    j = jobs[0]
    assert j.id == "104_8u59p01"
    assert j.title == "Flutter 工程師"
    assert j.company == "Acme 科技"
    assert j.location == "台北市信義區"
    assert j.source == "104"
    assert j.url == "https://www.104.com.tw/job/8u59p01"


@pytest.mark.asyncio
async def test_104_salary_range_normal():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE_JOBS)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert jobs[0].salary_range == "70K–100K"


@pytest.mark.asyncio
async def test_104_salary_range_negotiable():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE_JOBS)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert jobs[1].salary_range == "面議"


@pytest.mark.asyncio
async def test_104_remote_detection():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE_JOBS)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert jobs[0].is_remote is False   # remoteWorkType=0
    assert jobs[1].is_remote is True    # remoteWorkType=1


@pytest.mark.asyncio
async def test_104_handles_http_error():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        error_resp = MagicMock()
        error_resp.status_code = 403
        mock_cffi.get.return_value = error_resp
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert jobs == []


@pytest.mark.asyncio
async def test_104_strips_highlight_markers():
    """104 wraps search keywords in [[[ ]]] — these should be stripped."""
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_RESPONSE_JOBS)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    # Description should not contain [[[ ]]]
    for j in jobs:
        assert "[[[" not in j.description
        assert "]]]" not in j.title


# ---------------------------------------------------------------------------
# Detail API skill enrichment (2026-07-02 tech debt)
# ---------------------------------------------------------------------------
_MOCK_DETAIL = {
    "data": {
        "condition": {
            "specialty": [
                {"code": "12001001046", "description": "Windows 10"},
                {"code": "12001008003", "description": "Excel"},
            ],
            "skill": [{"code": "x", "description": "不該被用到"}],
        }
    }
}


def _routed_get(url, **kwargs):
    """Route mock: detail endpoint vs search endpoint."""
    if "job/ajax/content/" in url:
        return _make_mock_response(_MOCK_DETAIL)
    return _make_mock_response(_MOCK_RESPONSE_JOBS)


@pytest.mark.asyncio
async def test_104_detail_enriches_skills():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.side_effect = _routed_get
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert jobs[0].skills == ["Windows 10", "Excel"]
    assert "不該被用到" not in jobs[0].skills


@pytest.mark.asyncio
async def test_104_detail_respects_max_details_cap():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.side_effect = _routed_get
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1, max_details=1)

    assert jobs[0].skills == ["Windows 10", "Excel"]
    assert jobs[1].skills == []


@pytest.mark.asyncio
async def test_104_detail_failure_keeps_empty_skills():
    def _detail_fails(url, **kwargs):
        if "job/ajax/content/" in url:
            resp = MagicMock()
            resp.status_code = 404
            return resp
        return _make_mock_response(_MOCK_RESPONSE_JOBS)

    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.side_effect = _detail_fails
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)

    assert all(j.skills == [] for j in jobs)
