# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
│   ├── crawler_cake.py      # CakeResume（httpx, Phase 1）
│   └── crawler_104.py       # 104（httpx + detail API, Phase 1）
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

### 關鍵設計決策

- **Skills filter** 是 Python-side post-DB filter（OR 邏輯）。大資料量時應改為 DB-side（Phase 2 技術債）。
- **`_upsert_jobs`** 僅更新 title/description/salary_range/skills/crawled_at，不更新 location/company（Phase 2 技術債）。
- **爬蟲排程**：APScheduler 每 6 小時執行，關鍵字：`["軟體", "工程師", "flutter", "backend"]`。
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

### Data flow（現況 M1–M3，mock JSON）

```
assets/mock/jobs.json
    → JobRepository (rootBundle)
    → jobListProvider (Riverpod FutureProvider)
    → JobListScreen (ConsumerStatefulWidget)
        → tap → GoRouter /jobs/:id → JobDetailScreen
            → _aiAnalysisProvider (FutureProvider.family)
                → AiService.analyze(jobSkills, userSkills)
```

### Data flow（Plan B 完成後，真實 API）

```
FastAPI Backend (localhost:8000)
    → api_client.dart (Dio)
    → JobRemoteDataSource
    → JobRepository（API 優先，失敗 fallback mock JSON）
    → jobListProvider → UI（同上）
```

> **Plan B 尚未實作**：`lib/core/network/api_client.dart`、`job_remote_datasource.dart`、sync UI button 都還未建立。

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

### AI service (`lib/core/ai/ai_service.dart`)

`AiService` defaults to **mock mode** when `kDebugMode == true` (i.e. every `flutter run` without `--release`). Mock mode calculates match score from skill overlap without any network call. Pass `CLAUDE_API_KEY` via `--dart-define` to enable real Claude API calls in any build mode.

### Code generation

The following files are **generated — do not edit manually**:
- `*.freezed.dart` — Freezed immutable model implementations
- `*.g.dart` — `json_serializable` + `riverpod_generator` output

Trigger re-generation whenever you add/change a `@freezed` class or `@riverpod` provider.

---

## Testing

### Flutter（`test/`）

| File | What it covers |
|------|----------------|
| `widget_test.dart` | `SkillChip` + `JobCard` widget rendering (M1) |
| `m2_widget_test.dart` | `FavoriteNotifier` + `ApplyStatusNotifier` unit tests (M2) |
| `m3_test.dart` | Filter logic, `AiService` mock, `UserProfileNotifier` (M3) |

All provider tests use `ProviderContainer` + `SharedPreferences.setMockInitialValues({})` — no Flutter widget pump needed.

```powershell
# Flutter: 30 tests
$env:PATH = "D:\flutter\bin;$env:PATH"; flutter test
```

### Backend（`backend/tests/`）

```powershell
# Backend: 20 tests
cd C:\dev\career_pilot\backend
.\.venv\Scripts\Activate.ps1
pytest -v
```

See [Backend 測試](#backend-tests) section above for file breakdown.
