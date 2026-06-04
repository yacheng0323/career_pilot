# AI Job Finder App - MVP PRD

## 目標
建立一個 Flutter App，展示多來源職缺列表，並提供 AI 摘要與求職追蹤功能。

## 第一版不做
- 不做登入
- 不做真實爬蟲
- 不做自動投履歷
- 不做即時同步
- 不做推播
- 不做完整後端

## 第一版要做
1. 首頁：職缺列表
2. 搜尋：關鍵字搜尋
3. 篩選：地點 / 遠端 / 薪資 / 技能
4. 詳情頁：職缺內容、公司資訊、技能標籤
5. 收藏：本地收藏職缺
6. 應徵狀態：想投 / 已投 / 面試 / 已拒絕
7. AI 摘要：根據職缺內容產生 3 點摘要
8. AI 匹配度：根據我的技能與職缺要求，給出匹配分析

## 資料來源
第一版使用本地 mock JSON。
未來再改成 API / crawler / third-party source。

## 技術
- Flutter
- Riverpod
- Freezed
- GoRouter
- Dio, reserved for future API
- Local storage: SharedPreferences