# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Milestone Roadmap

| Milestone | 狀態 | 主要功能 | 分支 |
|-----------|------|---------|------|
| **M1** | ✅ 完成 | Job List + Detail Screen，mock JSON，GoRouter，Riverpod | `main` |
| **M2** | ✅ 完成 | 收藏（FavoriteNotifier）、應徵狀態、篩選 chips | `main` |
| **M3** | ✅ 完成 | 進階篩選（技能/地點）、UserProfile、AI 摘要+匹配度（mock）| `main` |
| **Backend** | ✅ 完成 | Python FastAPI + SQLite + Remotive/Arbeitnow 爬蟲 | `dev` |
| **Plan B** | ✅ 完成 | Flutter 串接後端 API，ApiClient，SyncNotifier，mock fallback | `dev` |
| **M4a** | 🔲 進行中 | 台灣職缺（104 Playwright + Yourator）| `feature/m4a-taiwan-crawler` |
| **M4b** | ✅ 完成 | Skeleton loader、深色模式、Empty state、Pull-to-refresh、真實 Claude AI | `dev` |
| **M4c** | 🔲 未來 | 求職 Kanban（拖拉卡片、備忘錄、面試日期） | TBD |

> Spec 文件：`docs/superpowers/specs/`
> 實作計畫：`docs/superpowers/plans/`

### M4 設計重點（已 brainstorm，待實作）

**M4a — 台灣爬蟲**
- `backend/crawlers/crawler_yourator.py`：httpx + Yourator 公開 JSON API
- `backend/crawlers/crawler_104_pw.py`：Playwright headless 繞過 Cloudflare
- 安裝：`pip install playwright && python -m playwright install chromium`

**M4b — UI + AI（✅ 已完成）**
- `shimmer: ^3.0.0` — JobCardSkeleton（6 張 placeholder cards 在載入時顯示）
- `AppTheme.dark` — 深色模式，`ThemeMode.system` 跟隨裝置設定
- `_EmptyState` widget — 無資料時顯示插圖 + 說明 + 立即同步按鈕
- Pull-to-refresh — `RefreshIndicator` 包住 `ListView`
- `AiService` — `useMock = apiKey.isEmpty`，有 key 時自動用真實 Claude API

---

## Git 分支策略

| 分支 | 用途 |
|------|------|
| `main` | 穩定版本，只接受來自 `dev` 的 merge |
| `dev` | 主開發分支，所有 feature 從這裡分出、merge 回這裡 |
| `feature/*` | 單一功能開發（e.g. `feature/plan-b-api-integration`） |

```powershell
# 開新 feature 分支
git checkout dev
git checkout -b feature/<name>

# feature 完成後 merge 回 dev
git checkout dev
git merge --no-ff feature/<name>
```

---

## Superpowers Skills

This project uses the [superpowers](https://github.com/obra/superpowers) methodology. Skills are located in `.claude/skills/`. **Before responding to any request, invoke the `using-superpowers` skill** to determine which skills apply.

Available skills:
- `using-superpowers` — start here every session
- `brainstorming` — design before implementation
- `writing-plans` — implementation planning
- `executing-plans` — working through a plan
- `test-driven-development` — TDD red/green/refactor
- `systematic-debugging` — root-cause debugging
- `verification-before-completion` — evidence-gated completion claims
- `requesting-code-review` / `receiving-code-review` — review workflows
- `subagent-driven-development` — parallel subagent execution
- `dispatching-parallel-agents` — concurrent independent tasks
- `finishing-a-development-branch` — branch completion and PR
- `using-git-worktrees` — isolated workspaces
- `writing-skills` — creating new skills

## Common Commands

> Flutter is installed at `D:\flutter\bin`. Set PATH before running Flutter commands in a new shell:
> ```powershell
> $env:PATH = "D:\flutter\bin;$env:PATH"
> ```

```powershell
# Install dependencies
flutter pub get

# Analyze (zero-issue gate — must pass before every commit)
dart analyze lib/

# Run all tests
flutter test

# Run a single test file
flutter test test/m3_test.dart

# Run a single test by name
flutter test --name "filter logic remoteOnly"

# Code generation (required after editing any @freezed model or @riverpod provider)
dart run build_runner build --delete-conflicting-outputs

# Run on Android emulator (must be in C:\dev\career_pilot — path must be ASCII)
flutter run

# Run with real Claude AI (skip mock mode)
flutter run --dart-define=CLAUDE_API_KEY=sk-ant-xxxxx
```

> **Windows path warning**: The project must live under an ASCII path (e.g. `C:\dev\career_pilot`). Gradle and `aapt` break on non-ASCII paths (e.g. `桌面`). See `android/gradle.properties` for the `android.overridePathCheck=true` override already in place.

---

## Backend (Python FastAPI)

後端爬蟲服務位於 `backend/`，提供職缺 REST API 給 Flutter App。

### 啟動後端

```powershell
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1           # 啟動 venv（Python 3.12）

# 啟動 server（port 8000）
uvicorn backend.main:app --reload --port 8000

# 執行所有後端測試（20 tests）
pytest -v

# 執行單一測試檔
pytest tests/test_api_jobs.py -v

# 安裝依賴（含 dev）
pip install -r requirements-dev.txt
```

> **Android emulator** 連 localhost 要用 `http://10.0.2.2:8000`，iOS simulator 用 `http://localhost:8000`。

### Backend 架構

```
backend/
├── main.py                  # FastAPI app + APScheduler lifespan
├── database.py              # SQLite engine（DATABASE_URL env var）+ get_session()
├── scheduler.py             # run_all_crawlers(), _upsert_jobs(), create_scheduler()
├── models/job.py            # Job (SQLModel), JobCreate, JobResponse (camelCase)
├── routers/
│   ├── jobs.py              # GET /api/v1/jobs, GET /api/v1/jobs/{id}
│   └── sync.py              # POST /api/v1/sync, GET /api/v1/sync/status
├── crawlers/
│   ├── base.py              # BaseCrawler ABC（make_id, _sleep 1-3s）
│   ├── crawler_remotive.py  # Remotive.com（httpx, 公開 API）✅
│   ├── crawler_arbeitnow.py # Arbeitnow.com（httpx, 公開 API）✅
│   ├── crawler_cake.py      # CakeResume（舊，API 404，停用）❌
│   └── crawler_104.py       # 104（舊，Cloudflare 403，停用）❌
├── requirements.txt         # runtime deps
├── requirements-dev.txt     # runtime + pytest/respx/pytest-asyncio
└── tests/                   # pytest, 20 tests
```

### API Endpoints

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/v1/jobs` | 職缺列表，query: `q`, `location`, `remote`, `skills`, `source`, `page`, `limit` |
| GET | `/api/v1/jobs/{id}` | 單一職缺（404 if not found） |
| POST | `/api/v1/sync` | 手動觸發爬蟲，回傳 `{"jobsUpserted": N}` |
| GET | `/api/v1/sync/status` | 上次爬蟲時間與狀態 |
| GET | `/health` | 健康檢查 |

### 現有爬蟲

| 爬蟲 | 來源 | 方法 | 狀態 |
|------|------|------|------|
| `crawler_remotive.py` | Remotive.com | httpx，公開 API | ✅ 正常，~96 筆/次 |
| `crawler_arbeitnow.py` | Arbeitnow.com | httpx，公開 API | ✅ 正常，~100 筆/頁 |
| `crawler_cake.py` | CakeResume | httpx（舊）| ❌ API 已 404，停用 |
| `crawler_104.py` | 104 | httpx（舊）| ❌ Cloudflare 403，停用 |

> M4a 計畫新增：`crawler_yourator.py`（httpx）+ `crawler_104_pw.py`（Playwright）

### 關鍵設計決策

- **爬蟲策略**：全量抓取，不做 keyword 過濾；篩選統一在 API query 層處理。
- **Skills filter** 是 Python-side post-DB filter（OR 邏輯）。大資料量時應改為 DB-side（M4 技術債）。
- **`_upsert_jobs`** 僅更新 title/description/salary_range/skills/crawled_at，不更新 location/company（技術債）。
- **爬蟲排程**：APScheduler 每 6 小時執行。
- **JobResponse** 使用 camelCase（`isRemote`, `salaryRange`, `crawledAt`）對應 Flutter Freezed model。

### Backend 測試

| 檔案 | 說明 |
|------|------|
| `tests/test_models.py` | Job/JobCreate/JobResponse 欄位與 from_job() |
| `tests/test_database.py` | SQLite init + session fixture |
| `tests/test_api_jobs.py` | 8 個 API 端點測試（含篩選、分頁、404）|
| `tests/test_crawler_cake.py` | CakeResume mock（respx）|
| `tests/test_crawler_104.py` | 104 mock（respx）|
| `tests/test_sync.py` | sync endpoint + error handling |

所有測試用 in-memory SQLite（`conftest.py` fixtures），不需要網路。

---

## Architecture

Feature-first folder layout under `lib/`:

```
lib/
├── app/           # MaterialApp.router + GoRouter definitions
├── core/
│   ├── ai/        # AiService (Claude API wrapper)
│   ├── persistence/  # SharedPreferences helpers
│   └── theme/     # AppTheme
└── features/
    ├── jobs/
    │   ├── data/         # JobRepository (loads assets/mock/jobs.json)
    │   ├── domain/       # Job (Freezed model)
    │   └── presentation/
    │       ├── providers/ # jobListProvider, FavoriteNotifier, ApplyStatusNotifier
    │       ├── screens/   # JobListScreen, JobDetailScreen
    │       └── widgets/   # JobCard, SkillChip
    └── profile/
        ├── domain/        # UserProfile (Freezed model)
        └── presentation/
            ├── providers/ # UserProfileNotifier
            └── screens/   # ProfileScreen (/profile)
```

### Data flow（現況，真實 API + mock fallback）

```
FastAPI Backend (localhost:8000)
    → ApiClient (Dio, lib/core/network/api_client.dart)
    → JobRemoteDataSource (lib/features/jobs/data/job_remote_datasource.dart)
    → JobRepository — API 優先，ApiException 時 fallback mock JSON
    → jobListProvider (Riverpod, @riverpod)
    → JobListScreen (ConsumerStatefulWidget)
        ├── 載入中 → JobCardSkeleton × 6（shimmer）
        ├── 無資料 → _EmptyState（立即同步按鈕）
        └── tap → GoRouter /jobs/:id → JobDetailScreen
                    → _aiAnalysisProvider (FutureProvider.family)
                        → AiService.analyze(jobSkills, userSkills)
                            ├── apiKey 空  → mock（技能 overlap 計算）
                            └── apiKey 非空 → 真實 Claude API
```

### State management patterns

- All providers use **Riverpod code-gen** (`@riverpod` / `@Riverpod`). After editing a provider, run `build_runner`.
- `sharedPreferencesProvider` (keepAlive, in `favorite_provider.dart`) is the single SharedPreferences instance shared across all persistence notifiers.
- `FavoriteNotifier`, `ApplyStatusNotifier`, `UserProfileNotifier` all `ref.watch(sharedPreferencesProvider.future)` and write back directly — no separate `PersistenceService` abstraction is used in the live providers.

### Routes

| Path | Screen |
|------|--------|
| `/` | `JobListScreen` |
| `/jobs/:id` | `JobDetailScreen` |
| `/profile` | `ProfileScreen` |

### UI 元件（M4b 已完成）

```
lib/features/jobs/presentation/widgets/
└── job_card_skeleton.dart   # Shimmer skeleton（6 張 placeholder，深/淺色自適應）

lib/core/theme/app_theme.dart
├── AppTheme.light           # 淺色 ThemeData
└── AppTheme.dark            # 深色 ThemeData（M4b 新增）

lib/app/app.dart
└── themeMode: ThemeMode.system   # 跟隨裝置深/淺色設定（M4b 新增）
```

### AI service (`lib/core/ai/ai_service.dart`)

判斷邏輯：`useMock = useMock ?? apiKey.isEmpty`

| 情況 | 行為 |
|------|------|
| `CLAUDE_API_KEY` 未傳（空字串）| mock mode（技能 overlap 計算，0 費用）|
| `CLAUDE_API_KEY=sk-ant-xxx` 傳入 | 真實 Claude API（`claude-3-5-haiku-20241022`）|

```powershell
# 啟用真實 AI
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 `
            --dart-define=CLAUDE_API_KEY=sk-ant-xxxxx
```

### Code generation

The following files are **generated — do not edit manually**:
- `*.freezed.dart` — Freezed immutable model implementations
- `*.g.dart` — `json_serializable` + `riverpod_generator` output

Trigger re-generation whenever you add/change a `@freezed` class or `@riverpod` provider.

---

## Testing

### Flutter（`test/`）

| File | Tests | What it covers |
|------|-------|----------------|
| `widget_test.dart` | 6 | `SkillChip` + `JobCard` widget rendering (M1) |
| `m2_widget_test.dart` | 8 | `FavoriteNotifier` + `ApplyStatusNotifier` (M2) |
| `m3_test.dart` | 16 | Filter logic, `AiService` mock, `UserProfileNotifier` (M3) |
| `api_client_test.dart` | 4 | `ApiClient` baseUrl + `ApiException` (Plan B) |
| `job_repository_test.dart` | 3 | Remote datasource + fallback logic (Plan B) |
| `m4b_test.dart` | 8 | `AppTheme.dark` + `AiService` key 判斷 (M4b) |
| **Total** | **45** | |

All provider tests use `ProviderContainer` + `SharedPreferences.setMockInitialValues({})`.

```powershell
# Flutter: 45 tests
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
flutter test
```

### Backend（`backend/tests/`）

```powershell
# Backend: 20 tests
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest -v
```

See [Backend 測試](#backend-tests) section above for file breakdown.
