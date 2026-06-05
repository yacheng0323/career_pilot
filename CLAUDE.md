# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚠️ 重要規則（Claude 每次讀取此檔案都必須遵守）

> **每當有任何重大變更、新功能、修改、新增、刪除時，Claude 必須：**
>
> 1. **建立或更新對應的文件**
>    - 新 spec → `docs/superpowers/specs/YYYY-MM-DD-<topic>.md`
>    - 新實作計畫 → `docs/superpowers/plans/YYYY-MM-DD-<feature>.md`
>    - 研究記錄 → `docs/superpowers/specs/YYYY-MM-DD-<topic>-research.md`
>
> 2. **更新 `CLAUDE.md`（本檔案）**
>    - Milestone Roadmap 狀態更新（🔲 → ✅）
>    - 新爬蟲 / 新 API / 新架構 → 補充到對應章節
>    - 測試數量變動 → 更新 Testing 表格
>    - 技術決策 → 補充到「關鍵設計決策」或「已知技術債」
>
> 3. **Commit 文件變更**（不要讓文件落後於程式碼）
>
> **適用場景：** 新功能、爬蟲新增/停用、API 發現、架構調整、測試新增、技術債確認、Milestone 完成。
>
> **不適用場景：** 單行 bug fix、typo 修正、格式調整。

---

## Milestone Roadmap

| Milestone | 狀態 | 主要功能 | 合入分支 |
|-----------|------|---------|---------|
| **M1** | ✅ 完成 | Job List + Detail Screen，mock JSON，GoRouter，Riverpod | `main` |
| **M2** | ✅ 完成 | 收藏（FavoriteNotifier）、應徵狀態（ApplyStatus）、篩選 chips | `main` |
| **M3** | ✅ 完成 | 進階篩選（技能/地點）、UserProfile 頁、AI 摘要+匹配度（mock）| `main` |
| **Backend** | ✅ 完成 | Python FastAPI + SQLite，Remotive + Arbeitnow 爬蟲 | `dev` |
| **Plan B** | ✅ 完成 | Flutter 串接後端 API，ApiClient (Dio)，SyncNotifier，mock fallback | `dev` |
| **M4a** | ✅ 完成 | 台灣職缺：Yourator (httpx) + **104 (curl_cffi)**，29 後端 tests | `dev` |
| **M4b** | ✅ 完成 | Skeleton loader、深色模式、Empty state、Pull-to-refresh、真實 Claude AI | `dev` |
| **M4c** | 🔲 未來 | 求職 Kanban（拖拉卡片、備忘錄、面試日期提醒）| TBD |

> Spec 文件：`docs/superpowers/specs/`
> 實作計畫：`docs/superpowers/plans/`

### M4 已完成功能摘要

**M4a — 台灣爬蟲（✅）**
- `crawler_yourator.py`：httpx，`api/v4/jobs`，~100 筆/次，台灣中文職缺
- `crawler_104_cffi.py`：`curl_cffi impersonate="chrome124"`，120K+ 台灣職缺，繞過 Cloudflare
- 關鍵突破：`curl_cffi` 模擬 Chrome TLS fingerprint（JA3/JA4），httpx/Playwright 均無效

**M4b — UI + AI（✅）**
- `shimmer: ^3.0.0` — JobCardSkeleton（6 張 shimmer placeholder cards）
- `AppTheme.dark` + `ThemeMode.system` — 深色模式跟隨裝置
- `_EmptyState` — 無資料時顯示說明 + 立即同步按鈕
- `RefreshIndicator` — 下拉重新整理
- `AiService.useMock = apiKey.isEmpty` — 有 key 自動用真實 Claude API

---

## Git 分支策略

| 分支 | 用途 |
|------|------|
| `main` | 穩定版本，只接受來自 `dev` 的 merge |
| `dev` | 主開發分支，所有 feature 從這裡分出、merge 回這裡 |
| `feature/*` | 單一功能開發 |

```powershell
git checkout dev
git checkout -b feature/<name>          # 開新 feature 分支
git checkout dev
git merge --no-ff feature/<name>        # feature 完成後 merge
```

---

## Superpowers Skills

本專案使用 [superpowers](https://github.com/obra/superpowers) 開發方法論。Skills 在 `.claude/skills/`。

| Skill | 使用時機 |
|-------|---------|
| `using-superpowers` | 每次 session 起點 |
| `brainstorming` | 實作前設計 |
| `writing-plans` | 產出實作計畫 |
| `executing-plans` | 依計畫執行 |
| `test-driven-development` | TDD 紅綠重構 |
| `systematic-debugging` | 根因除錯 |
| `verification-before-completion` | 完成前需有執行證據 |
| `subagent-driven-development` | 每 task 派 subagent + 兩階段 review |
| `requesting-code-review` / `receiving-code-review` | review 流程 |
| `finishing-a-development-branch` | 分支完成與 PR |

---

## Common Commands

> Flutter 安裝於 `D:\flutter\bin`，每次新 shell 需設定 PATH：
> ```powershell
> $env:PATH = "D:\flutter\bin;$env:PATH"
> ```

```powershell
# Flutter
flutter pub get
dart analyze lib/                                           # zero-issue gate
flutter test                                               # 45 tests
dart run build_runner build --delete-conflicting-outputs   # 修改 @freezed / @riverpod 後執行

# 啟動（Android emulator 預設）
.\dev.ps1

# 啟用真實 Claude AI
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
            --dart-define=CLAUDE_API_KEY=sk-ant-xxxxx
```

> **Windows 路徑警告：** 專案必須在 ASCII 路徑（如 `C:\dev\career_pilot`）。
> 中文路徑（如 `桌面`）會讓 Gradle 和 `aapt` 崩潰。

---

## 一鍵啟動腳本（dev.ps1）

```powershell
.\dev.ps1                    # Android emulator（預設）
.\dev.ps1 -Target ios        # iOS simulator
.\dev.ps1 -Target web        # Flutter Web
.\dev.ps1 -BackendOnly       # 只啟動後端
.\dev.ps1 -FlutterOnly       # 只啟動 Flutter（後端已在跑）
```

腳本行為：
1. 檢查 venv，不存在時自動建立並 `pip install -r requirements-dev.txt`
2. 背景啟動 `uvicorn backend.main:app --reload`（從專案根目錄）
3. 輪詢 `/health`，最多等 15 秒確認後端就緒
4. 啟動 `flutter run --dart-define=API_BASE_URL=...`
5. 按 `q` 退出 Flutter 後，自動停止後端 process

---

## Backend（Python FastAPI）

### 啟動後端

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1           # Python 3.12

uvicorn backend.main:app --reload --port 8000   # 從專案根目錄！不是 backend/ 子目錄
pytest -v                                        # 29 tests
pip install -r requirements-dev.txt
```

> ⚠️ uvicorn 必須從 `C:\dev\career_pilot`（專案根目錄）執行，因為 `main.py` 裡所有 import 都是 `from backend.xxx import ...`。

> **Android emulator** 用 `http://10.0.2.2:8000`，iOS simulator 用 `http://localhost:8000`。

### Backend 架構

```
backend/
├── main.py                    # FastAPI app + APScheduler lifespan（啟動 4 個爬蟲）
├── database.py                # SQLite engine（DATABASE_URL env var）+ get_session()
├── scheduler.py               # run_all_crawlers(), _upsert_jobs(), create_scheduler()
├── models/job.py              # Job (SQLModel), JobCreate, JobResponse (camelCase)
├── routers/
│   ├── jobs.py                # GET /api/v1/jobs, GET /api/v1/jobs/{id}
│   └── sync.py                # POST /api/v1/sync, GET /api/v1/sync/status
├── crawlers/
│   ├── base.py                # BaseCrawler ABC（make_id, _sleep 1-3s random）
│   ├── crawler_remotive.py    # Remotive.com（httpx）✅ ~96 筆（英文遠端）
│   ├── crawler_arbeitnow.py   # Arbeitnow.com（httpx）✅ ~100 筆/頁（英文）
│   ├── crawler_yourator.py    # Yourator.co（httpx）✅ ~100 筆（台灣中文）
│   ├── crawler_104_cffi.py    # 104.com.tw（curl_cffi）✅ 120K+ 筆（台灣）
│   ├── crawler_cake.py        # ❌ CakeResume（API 404，停用）
│   └── crawler_104.py         # ❌ 104 httpx（Cloudflare 403，停用）
├── scripts/                   # 探測/研究腳本（不進生產）
├── requirements.txt           # runtime deps（含 curl-cffi==0.15.0）
├── requirements-dev.txt       # runtime + pytest/respx/pytest-asyncio
└── tests/                     # pytest，29 tests
```

### API Endpoints

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/v1/jobs` | 職缺列表，query: `q`, `location`, `remote`, `skills`, `source`, `page`, `limit` |
| GET | `/api/v1/jobs/{id}` | 單一職缺（404 if not found）|
| POST | `/api/v1/sync` | 手動觸發所有爬蟲，回傳 `{"jobsUpserted": N}` |
| GET | `/api/v1/sync/status` | 上次爬蟲時間與 jobsUpserted 數 |
| GET | `/health` | `{"status":"ok"}` |

### 爬蟲技術細節

#### Yourator（httpx）

```
GET https://www.yourator.co/api/v4/jobs?page=1&per_page=20
Headers: User-Agent Chrome + Referer: https://www.yourator.co/jobs
Response: {"payload": {"hasMore": true, "nextPage": 2, "jobs": [...]}}
Job fields: id, name, path, salary, location, tags[], company.brand
URL 組合: https://www.yourator.co + job.path
```

#### 104（curl_cffi — 突破 Cloudflare）

```
GET https://www.104.com.tw/jobs/search/api/jobs
Params: jobcat=2007001000 (IT), page, rows=30, order=11
Headers: Chrome UA + Referer: https://www.104.com.tw/
impersonate="chrome124"  ← 關鍵：模擬 Chrome TLS fingerprint

Response: {
  "data": [...],           // job list（直接是 list，非 dict）
  "metadata": {"pagination": {total, currentPage, lastPage}}
}
Job fields: jobNo, jobName, custName, jobAddrNoDesc, description,
            link.job (URL), remoteWorkType (0=現場/1=遠端/2=混合),
            salaryLow, salaryHigh
薪資解析: salaryHigh >= 9999999 → "面議"，否則 "{low//1000}K–{high//1000}K"
```

**為何 curl_cffi 有效：**

| 方法 | 結果 | 原因 |
|------|------|------|
| httpx | ❌ 403 | TLS Client Hello 不像 Chrome |
| Playwright headless | ❌ 0 筆 | `navigator.webdriver` flag 被偵測 |
| Playwright stealth | ❌ 0 筆 | JA3/JA4 TLS hash 仍被辨識 |
| **curl_cffi chrome124** | ✅ **200** | 精確複製 Chrome 124 TLS fingerprint（cipher suites、extensions 順序、JA3/JA4 hash）|

### 爬蟲設計決策

- **全量抓取**：爬蟲不做 keyword 過濾，全部存入 DB，篩選在 API query 層做
- **Skills filter**：Python-side post-DB filter（OR 邏輯），大資料量時應改為 DB-side（技術債）
- **_upsert_jobs**：僅更新 title/description/salary_range/skills/crawled_at，不更新 location/company（技術債）
- **排程**：APScheduler 每 6 小時執行，4 個爬蟲依序執行
- **爬蟲順序**：Remotive → Arbeitnow → Yourator → Crawler104Cffi

### Backend 測試

| 檔案 | Tests | 說明 |
|------|-------|------|
| `test_models.py` | 3 | Job/JobCreate/JobResponse 欄位 |
| `test_database.py` | 2 | SQLite init + session fixture |
| `test_api_jobs.py` | 8 | API 端點（篩選、分頁、404）|
| `test_crawler_cake.py` | 2 | CakeResume mock（respx）|
| `test_crawler_104.py` | 2 | 104 httpx mock（respx）|
| `test_sync.py` | 3 | sync endpoint + error handling |
| `test_crawler_yourator.py` | 3 | Yourator mock（respx）|
| `test_crawler_104_cffi.py` | 6 | 104 curl_cffi mock（unittest.mock）|
| **Total** | **29** | |

所有測試用 in-memory SQLite，不需要網路。

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest -v    # 29 tests
```

---

## Flutter App 架構

Feature-first layout under `lib/`：

```
lib/
├── main.dart
├── app/
│   ├── app.dart       # ProviderScope + MaterialApp.router（light/dark/system）
│   └── router.dart    # GoRouter: / → /jobs/:id → /profile
├── core/
│   ├── ai/            # AiService（Claude API，mock/real 依 apiKey 判斷）
│   ├── network/       # ApiClient (Dio), ApiException
│   ├── persistence/   # PersistenceService（SharedPreferences wrapper）
│   └── theme/         # AppTheme.light + AppTheme.dark
└── features/
    ├── jobs/
    │   ├── data/         # JobRepository（API 優先 + mock fallback）
    │   │                 # JobRemoteDataSource（呼叫 FastAPI）
    │   ├── domain/       # Job（Freezed，含 url?, crawledAt?）
    │   └── presentation/
    │       ├── providers/ # jobListProvider, apiClientProvider
    │       │              # FavoriteNotifier, ApplyStatusNotifier
    │       ├── screens/   # JobListScreen, JobDetailScreen
    │       └── widgets/   # JobCard, SkillChip, JobCardSkeleton
    ├── profile/
    │   ├── domain/        # UserProfile（Freezed）
    │   └── presentation/
    │       ├── providers/ # UserProfileNotifier
    │       └── screens/   # ProfileScreen (/profile)
    └── sync/
        └── presentation/
            └── providers/ # SyncNotifier（POST /api/v1/sync）
```

### Data Flow

```
FastAPI Backend (localhost:8000)
    ↓ Dio (ApiClient)
JobRemoteDataSource.fetchAll()
    ↓
JobRepository.fetchAll()   ← API 優先，ApiException → fallback mock JSON
    ↓
jobListProvider (Riverpod FutureProvider, keepAlive: false)
    ↓
JobListScreen (ConsumerStatefulWidget)
    ├── 載入中 → _SkeletonList（6 × JobCardSkeleton shimmer）
    ├── 無資料 → _EmptyState（插圖 + 立即同步按鈕）
    ├── 下拉 → RefreshIndicator → ref.invalidate(jobListProvider)
    └── tap card → /jobs/:id → JobDetailScreen
            ├── _AiAnalysisCard → _aiAnalysisProvider → AiService
            │       ├── apiKey 空 → mock（技能 overlap 計算）
            │       └── apiKey 非空 → Claude API claude-3-5-haiku
            └── _ApplyStatusRow → ApplyStatusNotifier（SharedPreferences）
```

### Routes

| Path | Screen |
|------|--------|
| `/` | `JobListScreen` |
| `/jobs/:id` | `JobDetailScreen` |
| `/profile` | `ProfileScreen` |

### 主要 Provider 一覽

| Provider | 類型 | 說明 |
|----------|------|------|
| `apiClientProvider` | `@Riverpod(keepAlive: true)` | Dio instance（單例）|
| `jobListProvider` | `@riverpod Future<List<Job>>` | 職缺列表（帶 query 參數）|
| `sharedPreferencesProvider` | `@Riverpod(keepAlive: true)` | SharedPreferences 單例 |
| `favoriteNotifierProvider` | `@riverpod class` | 收藏 toggle + 持久化 |
| `applyStatusNotifierProvider` | `@riverpod class` (family) | 應徵狀態 per jobId |
| `userProfileNotifierProvider` | `@Riverpod(keepAlive: true) class` | 使用者技能 |
| `syncNotifierProvider` | `@riverpod class` | sync 狀態機 |

> 所有 Riverpod provider 使用 code-gen（`@riverpod`）。修改後執行：
> ```powershell
> dart run build_runner build --delete-conflicting-outputs
> ```

### AI Service

`lib/core/ai/ai_service.dart`

| 條件 | 行為 |
|------|------|
| `CLAUDE_API_KEY` 未傳（空字串）| mock mode：技能 overlap 計算，0 費用 |
| `CLAUDE_API_KEY=sk-ant-xxx` 傳入 | 真實 Claude API（`claude-3-5-haiku-20241022`）|

判斷邏輯：`useMock = useMock ?? apiKey.isEmpty`

### Flutter 依賴重點

| Package | 用途 |
|---------|------|
| `flutter_riverpod ^2.6` + `riverpod_annotation ^2.6` | 狀態管理 |
| `freezed_annotation ^2.4` + `freezed ^2.5` | Immutable model |
| `go_router ^14.6` | 路由 |
| `dio ^5.8` | HTTP client（串接後端 API）|
| `shared_preferences ^2.3` | 本地持久化 |
| `http ^1.2` | Claude API 呼叫 |
| `shimmer ^3.0` | Skeleton loader 動畫 |

### Code Generation

以下為自動生成檔案，**禁止手動修改**：
- `*.freezed.dart` — Freezed model 實作
- `*.g.dart` — json_serializable + riverpod_generator 輸出

---

## Testing

### Flutter（`test/`）— 45 tests

| File | Tests | What it covers |
|------|-------|----------------|
| `widget_test.dart` | 6 | SkillChip + JobCard widget rendering (M1) |
| `m2_widget_test.dart` | 8 | FavoriteNotifier + ApplyStatusNotifier (M2) |
| `m3_test.dart` | 16 | Filter logic, AiService mock, UserProfileNotifier (M3) |
| `api_client_test.dart` | 4 | ApiClient baseUrl + ApiException (Plan B) |
| `job_repository_test.dart` | 3 | RemoteDataSource + fallback (Plan B) |
| `m4b_test.dart` | 8 | AppTheme.dark + AiService key 判斷 (M4b) |
| **Total** | **45** | |

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
flutter test
```

### Backend（`backend/tests/`）— 29 tests

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest -v
```

---

## 已知技術債

| 項目 | 說明 | 優先 |
|------|------|------|
| Skills filter DB-side | 目前 Python post-filter，大資料量慢 | P1 |
| `_upsert_jobs` 欄位不完整 | location/company 更新時不覆蓋舊值 | P2 |
| 104 skills 欄位空 | `tags` 是工作特性碼（wf*），非技能；需抓 detail API | P2 |
| AI 結果未 cache | 每次開詳情頁都重新呼叫 AI（或計算）| P2 |
| Yourator description 只用 name | 完整描述需另呼叫 detail API | P3 |
| 1111 / LinkedIn 爬蟲 | 未評估（1111）/ 受限（LinkedIn API）| P3 |
