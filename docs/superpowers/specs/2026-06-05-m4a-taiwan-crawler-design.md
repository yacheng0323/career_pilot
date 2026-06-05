# M4a — 台灣職缺爬蟲 Design Spec
**Date:** 2026-06-05
**Status:** Research complete — ready for implementation
**Branch:** `feature/m4a-taiwan-crawler`

---

## 探測過程記錄

### 嘗試的平台

| 平台 | 方法 | 結果 | 結論 |
|------|------|------|------|
| Yourator `api/v2/jobs` | httpx | 404 | ❌ |
| Yourator `api/v4/jobs?page=1` | httpx（攔截發現）| 200, 20 筆/頁 | ✅ 可用 |
| 104 httpx 直接呼叫 | httpx | 403 Cloudflare | ❌ |
| 104 Playwright headless | Playwright | 0 結果（bot 偵測）| ❌ |
| 104 Playwright + stealth | Playwright stealth | 0 結果（仍偵測到）| ❌ |
| meet.jobs API | httpx | 回傳 HTML | ❌ |
| Arbeitnow | httpx 公開 API | ✅ 已使用 | 國際職缺 |
| Remotive | httpx 公開 API | ✅ 已使用 | 國際遠端職缺 |

### 104 反爬機制分析
104 在 headless 瀏覽器環境下刻意回傳「共 0 筆」結果，即使關鍵字為「軟體工程師」這樣的廣義詞。推測為：
- 偵測 `navigator.webdriver` flag
- 分析 HTTP fingerprint（TLS fingerprint、request order）
- 對 headless 回傳空結果（非 CAPTCHA，更難繞過）

**結論：104 短期內無法用 Playwright headless 爬取，記錄為技術債。**
可能的未來方案：residential proxy + 真實 Chrome + 帳號登入。

---

## Yourator API 規格

**Endpoint：** `GET https://www.yourator.co/api/v4/jobs`

**Query params：**
| Param | 說明 |
|-------|------|
| `page` | 頁碼（從 1 開始）|
| `per_page` | 每頁筆數（預設 20）|

**Response 結構：**
```json
{
  "payload": {
    "hasMore": true,
    "currentPage": 1,
    "nextPage": 2,
    "jobs": [
      {
        "id": 41887,
        "name": "職缺名稱",
        "path": "/companies/acme/jobs/41887",
        "salary": "月薪 60,000 - 100,000",
        "lastActiveAt": "一週內更新",
        "location": "台北市",
        "companyId": 3272,
        "tags": ["Flutter", "Dart"],
        "company": {
          "id": 3272,
          "path": "/companies/acme",
          "brand": "公司名稱",
          "enName": "acme",
          "logo": "https://...",
          "badges": ["verified"]
        },
        "thirdPartyUrl": null,
        "externalSource": null
      }
    ]
  }
}
```

**Headers 必要：**
- `User-Agent`: 一般瀏覽器 UA
- `Referer`: `https://www.yourator.co/jobs`（沒有也可以，但建議加）

**Rate：** 無明確限制，建議每頁間隔 1-2 秒。

---

## 實作範圍（M4a Phase 1）

### 新增檔案

| 檔案 | 說明 |
|------|------|
| `backend/crawlers/crawler_yourator.py` | Yourator httpx crawler |
| `backend/tests/test_crawler_yourator.py` | respx mock 測試 |

### 修改檔案

| 檔案 | 變更 |
|------|------|
| `backend/scheduler.py` | 加入 `YouratoCrawler` |
| `backend/requirements.txt` | 無需新依賴（httpx 已有）|

### 已安裝但暫不使用

| 套件 | 說明 |
|------|------|
| `playwright` | 已安裝（為 104 而裝）。104 爬蟲暫緩，playwright 留著供未來使用 |

### 不在範圍（技術債）

- 104 爬蟲（headless 偵測，需 residential proxy）
- 1111 爬蟲（未評估）
- meet.jobs（無公開 JSON API）

---

## Yourator JobCreate 欄位對應

| Yourator field | JobCreate field | 備註 |
|----------------|-----------------|------|
| `id` | `id` → `"yourator_{id}"` | |
| `name` | `title` | |
| `company.brand` | `company` | |
| `location` | `location` | |
| 固定 `False` | `is_remote` | Yourator 多為台灣現場職缺 |
| `salary` | `salary_range` | |
| `tags` | `skills` | |
| 需另取 description | `description` | 需再呼叫 `/api/v4/jobs/{id}` 取完整描述，或使用 name |
| `https://www.yourator.co{path}` | `url` | |

> **Description 策略：** 單一職缺 detail API `GET /api/v4/jobs/{id}` 取完整 description。
> 但為避免每筆都要額外一次 request，先以 `name`（職缺名稱）作為 description placeholder，
> 之後可加 detail 爬取。

---

## 驗收標準

1. `POST /api/v1/sync` 後 DB 有中文職缺（公司名、地點為中文）
2. `pytest tests/test_crawler_yourator.py` 全過（respx mock）
3. `pytest -v` 全套通過（20+ tests）
4. `dart analyze lib/` zero errors（後端改動不影響 Flutter）
