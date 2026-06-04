# Milestone 4 — 台灣職缺 + UI 打磨 + 真實 AI

**Date:** 2026-06-05
**Status:** Brainstorming approved — awaiting implementation plan
**Branch strategy:** `feature/m4a-taiwan-crawler`、`feature/m4b-ui-ai`（分支並行，互不依賴）

---

## 背景與動機

目前系統使用 Remotive + Arbeitnow 兩個國際遠端職缺 API，職缺以英文為主、與台灣求職市場脫節。
AI 功能僅使用 mock 模式，未接真實 Claude API。UI 缺少骨架屏、空白頁設計與深色模式，整體質感偏陽春。

---

## 目標

| 優先 | 功能 | 說明 |
|------|------|------|
| P0 | 台灣本地職缺 | 104（Playwright）+ Yourator（httpx） |
| P1 | UI 打磨 | Skeleton loader、Empty state、深色模式 |
| P1 | 真實 Claude AI | AiService 切換到真實 API，`--dart-define=CLAUDE_API_KEY` |

---

## 執行策略：方案 A（分批漸進）

### Milestone 4a — 台灣爬蟲
**Branch:** `feature/m4a-taiwan-crawler`

#### 範圍
| 平台 | 方法 | 優先 |
|------|------|------|
| **Yourator** | httpx + JSON API（公開，無需 browser） | Phase 1（本次）|
| **104** | Playwright headless browser，繞過 Cloudflare | Phase 1（本次）|
| **1111** | Playwright（反爬更強，需要更多測試） | Phase 2 |

#### 後端新增檔案
```
backend/crawlers/
├── crawler_yourator.py     # Yourator httpx crawler
└── crawler_104_pw.py       # 104 Playwright crawler
```

#### Scheduler 更新
- `run_all_crawlers()` 加入 `YouratoCrawler` + `Crawler104Playwright`
- Playwright 爬蟲需安裝 `playwright` 套件並下載 chromium browser binaries

#### 環境需求
```powershell
# 安裝 playwright
cd C:\dev\career_pilot\backend
.\.venv\Scripts\pip install playwright
.\.venv\Scripts\python -m playwright install chromium
```

#### 驗收標準
- `POST /api/v1/sync` 後 DB 中有台灣中文職缺
- 職缺標題、公司、地點為中文
- `dart analyze lib/` zero errors
- 後端 pytest 通過

---

### Milestone 4b — UI 打磨 + 真實 AI
**Branch:** `feature/m4b-ui-ai`

#### UI 打磨範圍

| 功能 | 說明 | 檔案 |
|------|------|------|
| **Skeleton loader** | JobListScreen 載入中顯示骨架屏（灰色 placeholder cards） | 新增 `widgets/job_card_skeleton.dart` |
| **Empty state** | 無職缺/無搜尋結果時顯示插圖 + 說明文字 | `job_list_screen.dart` |
| **深色模式** | AppTheme 加 `dark` ThemeData，跟隨系統設定 | `core/theme/app_theme.dart`、`app/app.dart` |
| **載入動畫** | 詳情頁 AI 分析 card 顯示 shimmer 動畫 | `job_detail_screen.dart` |
| **Pull-to-refresh** | JobListScreen 下拉重新整理 | `job_list_screen.dart` |

#### 真實 Claude AI 範圍

| 功能 | 說明 |
|------|------|
| **切換 mock → real** | `AiService` 在有 `CLAUDE_API_KEY` 時自動使用真實 API（目前 debug 模式強制 mock）|
| **API key 管理** | 文件說明如何用 `--dart-define=CLAUDE_API_KEY=sk-ant-xxx` 啟用 |
| **Retry + timeout** | 真實 API 加入 retry logic（最多 2 次）+ 10 秒 timeout |
| **Error UI** | API 呼叫失敗時顯示「AI 分析暫時不可用」而非空白 |

#### 新增依賴
```yaml
# pubspec.yaml
shimmer: ^3.0.0    # skeleton shimmer 動畫
```

#### 驗收標準
- `flutter test` all passed
- `dart analyze lib/` zero errors
- 深色模式跟隨系統切換
- Skeleton loader 在職缺載入前可見
- 帶 `CLAUDE_API_KEY` 啟動時 AI card 顯示真實摘要

---

## Milestone 4c（未來）— 求職 Kanban
**待後續 brainstorming**

- 應徵狀態升級為 Kanban 看板（拖拉卡片）
- 每個職缺可加備忘錄、面試日期
- 面試日程 Calendar view

---

## Out of Scope（本次）

- 1111 爬蟲（Phase 2）
- LinkedIn / Indeed（Phase 3）
- Push notification
- 後端部署到雲端
- 使用者登入 / 帳號系統
- Kanban（M4c）

---

## 技術風險

| 風險 | 說明 | 緩解方案 |
|------|------|---------|
| 104 Playwright 爬蟲被封 | 104 持續更新反爬策略 | Rate limiting + random delay；失敗 graceful degrade |
| Claude API 費用 | 真實 API 每次呼叫有費用 | debug 預設 mock；release 才用真實；結果 cache 到 SharedPreferences |
| Playwright 在 Windows 安裝問題 | chromium binary 約 200MB | 文件說明安裝步驟；CI 跳過 Playwright 測試 |
