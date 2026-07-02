# 實作計畫：爬蟲資料補全 + 1111 爬蟲

**Spec：** `specs/2026-07-02-crawler-enrichment-design.md`
**分支：** `feature/tech-debt-crawlers`（自 `dev`）

## Task 1：upsert 保護規則（TDD）
- [ ] 紅：`test_sync.py` — 新 skills 空 / description 空時保留舊值
- [ ] 綠：`scheduler.py` 條件覆蓋

## Task 2：104 detail skills（TDD）
- [ ] 紅：`test_crawler_104_cffi.py` — specialty→skills、max_details cap
- [ ] 綠：`crawler_104_cffi.py` `_enrich_skills()`（slug 自 url regex、前 N 筆、失敗跳過）

## Task 3：Yourator description（TDD）
- [ ] 紅：`test_crawler_yourator.py` — JSON-LD 抽取去 tag、未 enrich 空字串
- [ ] 綠：`crawler_yourator.py` `_enrich_descriptions()` + `_extract_jsonld_description()`

## Task 4：1111 爬蟲（TDD）
- [ ] 紅：`test_crawler_1111.py` — 欄位映射、highlight `<em>` 清除、error 韌性、分頁
- [ ] 綠：`crawlers/crawler_1111.py`（curl_cffi），`scheduler._get_crawlers()` 加入

## Task 5：Flutter source badge
- [ ] `job_card.dart` `_SourceBadge` 加 1111（紅 #E4002B）+ widget test

## Task 6：文件收尾
- [ ] CLAUDE.md：技術債表清空（AI cache 已於 M6 完成一併移除）、爬蟲章節、測試數
- [ ] merge → dev → push；main 待使用者確認
