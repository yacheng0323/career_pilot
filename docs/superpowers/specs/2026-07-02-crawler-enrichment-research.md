# 研究記錄：104 detail / Yourator detail / 1111 API（2026-07-02）

探測腳本：`backend/scripts/probe_tech_debt.py`、`probe_tech_debt2.py`

## 104 職缺詳情 API（skills 來源）✅

```
GET https://www.104.com.tw/job/ajax/content/{slug}
Headers: Chrome UA + Referer: https://www.104.com.tw/job/{slug}
impersonate="chrome124"（同 list API，必須）
```

- **slug ≠ jobNo**：用 jobNo 打會 404（error code 11201 職務不存在）。
  slug 是 `link.job` URL 的英數碼（如 `https://www.104.com.tw/job/8a8ak` → `8a8ak`）
- 回應：`data.condition.specialty[]` = `[{code, description}]`，description 即技能
  （實測：Windows 10 / Excel / Word）；`condition.skill[]` 為工作技能敘述，較雜，不用

## Yourator 完整描述 ✅

- `api/v4/jobs/{id}`、`api/v4{path}` 均 404 — **無公開 detail API**
- 職缺頁 HTML（`https://www.yourator.co{path}`）內嵌 JSON-LD：
  `<script type="application/ld+json">{"@type":"JobPosting","description":"..."}`
  description 為 HTML 字串（實測 656 字），去 tag 後即完整描述

## 1111 搜尋 API ✅

```
GET https://www.1111.com.tw/api/v1/search/jobs?keyword=python&page=1
（curl_cffi chrome124 實測 200；httpx 未驗證，統一用 curl_cffi）
Response: {"result": {"pagination": {page, limit:30, totalCount, totalPage},
                      "hits": [...]}}
```

hit 欄位：`jobId, title, companyName, description, salary（字串，如「月薪 650元以上」）,
workCity: {id, name}, industry, updateAt, jobType, require{...}`
- 職缺 URL：`https://www.1111.com.tw/job/{jobId}`
- 無 skills 欄位、無明確 remote 欄位

## LinkedIn — 不做

官方 API 需 Partner Program 授權，職缺資料不開放；網頁爬取違反 ToS 且有強反爬。
結論：排除，技術債關閉。
