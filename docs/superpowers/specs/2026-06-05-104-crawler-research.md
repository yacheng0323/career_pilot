# 104 爬蟲研究記錄
**Date:** 2026-06-05
**Status:** 已解決（curl_cffi）
**Branch:** `feature/m4a-taiwan-crawler`

---

## 問題描述

104.com.tw 是台灣最大的求職平台，但對爬蟲有嚴格防護：
- Cloudflare WAF 擋截非瀏覽器請求
- Bot 偵測機制在 headless 環境刻意回傳空結果

---

## 嘗試過的方法（時序）

### 1. httpx 直接呼叫 ❌

```python
import httpx
r = await client.get("https://www.104.com.tw/jobs/search/api/jobs", ...)
# 結果：HTTP 403 Cloudflare
```

**失敗原因：** httpx 使用 Python SSL library 的 TLS handshake，fingerprint 不像真實 Chrome。Cloudflare 的 JA3/JA4 fingerprint 偵測直接識別並封鎖。

---

### 2. Playwright headless browser ❌

```python
browser = await p.chromium.launch(headless=True)
page = await ctx.new_page()
await page.goto("https://www.104.com.tw/jobs/search/?keyword=工程師")
# 結果：頁面載入，但「共 0 筆」（刻意回傳空結果）
```

**失敗原因：**
- 104 偵測 `navigator.webdriver = true`（Playwright headless 特徵）
- 頁面完全載入，但 job list API 回傳空 list（非 CAPTCHA，是刻意行為）
- 截圖確認頁面是正常的 104 搜尋頁，只是沒有職缺

---

### 3. Playwright + stealth ❌

```python
from playwright_stealth import stealth_async
await stealth_async(page)
await page.add_init_script("""
    Object.defineProperty(navigator, 'webdriver', {get: () => undefined});
""")
```

**失敗原因：** stealth 套件移除了部分 webdriver flag，但 104 使用更深層的 TLS fingerprint 偵測（JA3/JA4）。即使 DOM 看起來是正常瀏覽器，底層 TLS handshake 仍暴露是 headless Chromium。

---

### 4. Playwright 非 headless（headless=False）❌

測試中發現 `headless=False` 在 Windows server 環境下 `spawn UNKNOWN` 錯誤，且即使成功也無法在自動化流程中使用。

---

### 5. 攔截 104 SPA 內部 API 呼叫 — 部分成功

```python
async def on_response(response):
    if "json" in ct and "104" in url:
        captured.append(...)

page.on("response", capture)
await page.goto("https://www.104.com.tw/jobs/search/?keyword=工程師")
```

**發現：** 104 SPA 呼叫了 `ajax/cards` endpoint，但這是廣告/UI config，不是職缺資料。真正的職缺 API 在 headless 環境下不被呼叫（被 bot 偵測 suppressed）。

---

### 6. curl_cffi ✅ 成功！

```python
from curl_cffi import requests as cffi_requests

r = cffi_requests.get(
    "https://www.104.com.tw/jobs/search/api/jobs",
    params={"jobcat": "2007001000", "page": "1", "rows": "30", "order": "11"},
    headers={"User-Agent": "Chrome/124...", "Referer": "https://www.104.com.tw/"},
    impersonate="chrome124",
    timeout=15,
)
# 結果：HTTP 200，32 筆職缺，JSON 格式
```

**成功原因：** `curl_cffi` 使用 libcurl 底層，能精確模擬 Chrome 124 的 TLS Client Hello：
- 相同的 cipher suites 順序
- 相同的 TLS extensions（ALPN, SNI, session ticket, etc.）
- 相同的 JA3/JA4 fingerprint hash
- 結果：Cloudflare 無法分辨真實 Chrome 與此請求

---

## 104 API 規格（發現於研究過程）

**Endpoint：** `GET https://www.104.com.tw/jobs/search/api/jobs`

**Query Params：**

| Param | 說明 | 範例 |
|-------|------|------|
| `jobcat` | 職類代碼 | `2007001000`（軟體工程師）|
| `page` | 頁碼 | `1` |
| `rows` | 每頁筆數 | `30` |
| `order` | 排序（11=最新）| `11` |
| `ro` | 工作類型（0=全職）| `0` |

**Response 結構：**

```json
{
  "data": [
    {
      "jobNo": "8u59p01",
      "jobName": "Flutter 工程師",
      "custName": "Acme 科技",
      "jobAddrNoDesc": "台北市信義區",
      "description": "負責 Flutter App 開發...",
      "descSnippet": "負責 [[[Flutter]]] App 開發...",
      "link": {
        "job": "https://www.104.com.tw/job/8u59p01",
        "cust": "https://www.104.com.tw/company/acme"
      },
      "remoteWorkType": 0,
      "salaryLow": 70000,
      "salaryHigh": 100000,
      "tags": {"wf1": {"desc": "週休二日", "param": "wf1"}},
      "jobCat": [...],
      "appearDate": "20260604"
    }
  ],
  "metadata": {
    "pagination": {
      "total": 120919,
      "currentPage": 1,
      "lastPage": 100,
      "count": 32
    }
  }
}
```

**注意事項：**
- `data` 直接是 list（不是 `data.list`）
- `tags` 是工作條件碼（wf = work feature），不是技術技能
- `descSnippet` 有 `[[[keyword]]]` 高亮標記，需移除
- `salaryHigh >= 9999999` 代表「面議」
- `remoteWorkType`: 0=現場, 1=全遠端, 2=混合

**IT 職類代碼：**
```python
_JOBCATS = [
    "2007001000",  # 軟體工程師
    "2007002000",  # 網路工程師
    "2007003000",  # 系統分析師
    "2007006000",  # 韌體/驅動工程師
]
```

---

## 實作檔案

| 檔案 | 說明 |
|------|------|
| `backend/crawlers/crawler_104_cffi.py` | 正式爬蟲實作 |
| `backend/tests/test_crawler_104_cffi.py` | 6 個 pytest tests（unittest.mock）|
| `backend/scripts/probe_104_methods.py` | 各方法探測腳本 |
| `backend/scripts/probe_104_curl_cffi.py` | curl_cffi 回應結構探測 |
| `backend/scripts/probe_104_structure.py` | 完整欄位結構探測 |

---

## 測試策略

由於 curl_cffi 使用 sync requests，無法用 respx（專為 httpx 設計）mock，
改用 `unittest.mock.patch`：

```python
from unittest.mock import patch, MagicMock

async def test_104_fetch_returns_jobs():
    with patch("backend.crawlers.crawler_104_cffi.cffi_requests") as mock_cffi:
        mock_cffi.get.return_value = _make_mock_response(_MOCK_DATA)
        crawler = Crawler104Cffi()
        jobs = await crawler.fetch(pages=1)
    assert jobs[0].id == "104_8u59p01"
```

**6 個測試覆蓋：**
1. `test_104_fetch_returns_jobs` — 基本欄位對應
2. `test_104_salary_range_normal` — 薪資格式（70K–100K）
3. `test_104_salary_range_negotiable` — 面議（salaryHigh >= 9999999）
4. `test_104_remote_detection` — remoteWorkType 判斷
5. `test_104_handles_http_error` — graceful degradation（403 → 空 list）
6. `test_104_strips_highlight_markers` — `[[[` `]]]` 移除

---

## 未來改進方向

1. **104 技術技能**：目前 skills 欄位為空（`tags` 是工作條件碼）。
   改進：額外呼叫 `GET /job-bank/jobs/{jobNo}` 取 detail，從 `requiredSkills` 欄位抽取技能。
   但會讓每筆職缺多一次 API 請求，需評估 rate limiting。

2. **Yourator description**：目前用 `name`（職缺名稱）當 description。
   改進：呼叫 `GET /api/v4/jobs/{id}` 取完整描述。

3. **curl_cffi impersonate 版本**：目前用 `chrome124`，未來 Chrome 更新後考慮升級到 `chrome131` 等。
