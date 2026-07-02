# 設計：爬蟲資料補全 + 1111 爬蟲（技術債清償）

**日期：** 2026-07-02
**研究：** `2026-07-02-crawler-enrichment-research.md`

## 範圍

| 債 | 方案 |
|----|------|
| 104 skills 空（P2）| list 後對前 N 筆抓 detail API，`condition.specialty[].description` → skills |
| Yourator description 只用 name（P3）| 對前 N 筆抓職缺頁 JSON-LD description |
| 1111 爬蟲（P3）| 新 `crawler_1111.py`（curl_cffi），`/api/v1/search/jobs` |
| AI cache（P2）| M6 已完成（`ai_cache_` + 測試），僅更新 CLAUDE.md |
| LinkedIn（P3）| 不做（API 受限 + ToS），文件關閉 |

## Detail 抓取成本控制

- 每次 crawl 只 enrich **前 N 筆**（list 為最新排序，新職缺優先）：
  104 `max_details=30`、Yourator `max_details=40`
- 每筆 detail 之間 0.3–0.8s 隨機延遲
- detail 失敗 → 靜默跳過（保持 list 資料）

## Upsert 保護規則（配合部分 enrich）

`_upsert_jobs` 更新既有 row 時：
- 新 `skills` 為空 → **保留舊值**（避免未 enrich 的批次清掉已補的技能）
- 新 `description` 為空 → **保留舊值**

Yourator 未 enrich 的職缺 description 改設 `""`（原本塞 name 佔位，會蓋掉舊的完整描述）。

## 1111 爬蟲

- source = `"1111"`，keyword 輪詢：`軟體工程師`、`python`、`前端工程師`
- 欄位映射：jobId→id、title、companyName→company、workCity.name→location、
  salary（字串直接用）、description（去 highlight `<em>`）、
  url=`https://www.1111.com.tw/job/{jobId}`、is_remote=False（API 無欄位）、skills=[]
- 排程順序：Remotive → Arbeitnow → Yourator → 104 → 1111

## Flutter

- `_SourceBadge` 加 `1111` → 「1111人力銀行」，紅 `#E4002B`

## 測試

| 檔 | 內容 |
|----|------|
| `test_crawler_104_cffi.py` | +detail skills parse（mock）、slug 解析、cap N |
| `test_crawler_yourator.py` | +JSON-LD description parse（respx mock HTML）、未 enrich 給空字串 |
| `test_crawler_1111.py` | 新：parse 欄位映射、分頁停止、error 韌性（mock curl_cffi）|
| `test_sync.py` | +upsert 保護規則（空 skills / 空 description 不覆蓋）|
| Flutter `widget_test.dart` 或 m4c | +1111 source badge |
