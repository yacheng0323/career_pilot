# Backend Crawler Service — Design Spec
**Date:** 2026-06-04  
**Topic:** 真實職缺資料來源（Python FastAPI + 爬蟲）  
**Status:** Approved

---

## Goal

將 Flutter App 的資料來源從靜態 mock JSON 換成自建後端爬蟲服務。
後端以 Python FastAPI + SQLite 在 localhost 運行，
定期爬取台灣（104、CakeResume）與國際（LinkedIn、Indeed）求職平台，
透過 REST API 提供職缺資料給 Flutter App。

---

## Architecture

```
Flutter App (C:\dev\career_pilot)
        │
        │  HTTP/JSON (Dio)
        ▼
FastAPI Server  localhost:8000
        │
        ├── JobRouter      /api/v1/jobs
        ├── SyncRouter     /api/v1/sync
        └── HealthRouter   /health
                │
        ┌───────┴────────┐
        │                │
   JobRepository      CrawlerEngine
   (SQLite via        ├── TaiwanCrawler
    SQLModel)         │   ├── crawler_104.py
                      │   ├── crawler_cake.py
                      │   └── crawler_1111.py
                      └── IntlCrawler
                          ├── crawler_linkedin.py
                          └── crawler_indeed.py
                                │
                          APScheduler
                          (每 6 小時自動 sync)
```

**資料流：**
1. App 啟動 → `GET /api/v1/jobs` 取得職缺列表
2. App 搜尋/篩選 → query params 傳給 FastAPI，DB 端過濾
3. 使用者手動觸發 → `POST /api/v1/sync` → 爬蟲立即執行
4. APScheduler 背景每 6 小時自動爬，結果寫入 SQLite

---

## API Contract

### Endpoints

| Method | Path | 說明 |
|--------|------|------|
| `GET` | `/api/v1/jobs` | 職缺列表（支援 query params） |
| `GET` | `/api/v1/jobs/{id}` | 單一職缺詳情 |
| `POST` | `/api/v1/sync` | 手動觸發全平台爬蟲 |
| `GET` | `/api/v1/sync/status` | 上次爬蟲時間與結果 |
| `GET` | `/health` | 健康檢查 |

### GET /api/v1/jobs Query Params

| Param | Type | 說明 |
|-------|------|------|
| `q` | string | 關鍵字（title + company + skills） |
| `location` | string | 地點精確比對 |
| `remote` | bool | 遠端篩選 |
| `skills` | string | 逗號分隔，OR 邏輯 |
| `source` | string | 來源平台 |
| `page` | int | 頁碼（預設 1） |
| `limit` | int | 每頁筆數（預設 20，最大 100） |

---

## Data Model

### DB Schema（SQLModel）

```python
class Job(SQLModel, table=True):
    id: str              # "{source}_{原始id}"，e.g. "104_12345"
    title: str
    company: str
    location: str
    is_remote: bool
    salary_range: str
    skills: str          # JSON array 存成 string
    description: str
    source: str          # "104" | "cake" | "1111" | "linkedin" | "indeed"
    url: str             # 原始職缺連結
    crawled_at: datetime
    expires_at: datetime | None = None
```

### API Response（Pydantic，camelCase 對應 Flutter）

```python
class JobResponse(BaseModel):
    id: str
    title: str
    company: str
    location: str
    isRemote: bool
    salaryRange: str
    skills: list[str]
    description: str
    source: str
    url: str
    crawledAt: datetime
```

Flutter `Job` Freezed model 新增 `url: String` 和 `crawledAt: DateTime` 欄位，其餘欄位完全相容。

---

## Crawler Strategy

### 平台分層

| 平台 | 方法 | 備註 |
|------|------|------|
| CakeResume | `httpx` + BeautifulSoup | 有公開 JSON API，MVP Phase 1 |
| 104 | `httpx` + 模擬 API | 有內部 REST API，MVP Phase 1 |
| 1111 | `httpx` + BeautifulSoup | 靜態 HTML，Phase 2 |
| LinkedIn | Playwright headless | 需 JS render，Phase 3 |
| Indeed | Playwright headless | 需 JS render，Phase 3 |

### 基底介面

```python
class BaseCrawler(ABC):
    source: str

    @abstractmethod
    async def fetch(self, keyword: str = "", pages: int = 3) -> list[JobCreate]:
        ...

    def deduplicate_id(self, raw_id: str) -> str:
        return f"{self.source}_{raw_id}"
```

### 排程

```python
scheduler.add_job(run_taiwan_crawlers, "interval", hours=6)
scheduler.add_job(run_intl_crawlers,   "interval", hours=6,
                  start_date="+3h")  # 錯開 3 小時
```

### 反爬對策

- Random sleep 1–3 秒（每次 request 之間）
- User-Agent rotation（輪換常見瀏覽器 UA）
- Retry 3 次 + exponential backoff
- 單平台失敗不影響其他平台（graceful degradation）

### MVP 實作順序

- **Phase 1（本次）**: CakeResume + 104
- **Phase 2**: 1111
- **Phase 3**: LinkedIn + Indeed

---

## Flutter App Changes

### 新增檔案

```
lib/core/network/
├── api_client.dart              # Dio 封裝，baseUrl 從 --dart-define 讀取
└── api_exception.dart           # 統一錯誤型別

lib/features/jobs/data/
└── job_remote_datasource.dart   # 呼叫 FastAPI

lib/features/sync/presentation/providers/
└── sync_provider.dart           # 手動 sync 觸發 + 狀態
```

### 修改檔案

| 檔案 | 變更 |
|------|------|
| `job_repository.dart` | 優先 API，失敗 fallback mock JSON（離線模式） |
| `job.dart` | 新增 `url`、`crawledAt` 欄位 |
| `job_list_screen.dart` | AppBar 加同步按鈕 + 上次更新時間 |
| `pubspec.yaml` | 取消 dio 的 comment |

### 環境設定

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS simulator / Web
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

---

## Testing Strategy

### 後端（pytest）

| 檔案 | 說明 |
|------|------|
| `test_api_jobs.py` | GET /jobs 格式、分頁、篩選 |
| `test_crawler_cake.py` | CakeResume 爬蟲（mock httpx） |
| `test_crawler_104.py` | 104 爬蟲（mock httpx） |
| `test_sync.py` | sync endpoint 觸發流程 |

### Flutter 端

| 檔案 | 說明 |
|------|------|
| `test/job_repository_test.dart` | API 成功回傳；API 失敗 fallback mock |
| `test/api_client_test.dart` | Dio timeout、retry 邏輯 |

---

## Project Structure（後端）

```
backend/
├── main.py
├── database.py
├── models/
│   └── job.py
├── routers/
│   ├── jobs.py
│   └── sync.py
├── crawlers/
│   ├── base.py
│   ├── crawler_104.py
│   └── crawler_cake.py
├── scheduler.py
├── requirements.txt
└── tests/
    ├── test_api_jobs.py
    ├── test_crawler_cake.py
    ├── test_crawler_104.py
    └── test_sync.py
```

---

## Out of Scope

- 部署到雲端（Phase 2+）
- 使用者登入 / 帳號系統
- LinkedIn / Indeed 爬蟲（Phase 3）
- 推播通知
- 職缺自動過期清理（僅記錄 `expires_at`，不實作清理）
