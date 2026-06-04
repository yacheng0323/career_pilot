# Decision Log

This file records key architectural and scope decisions made during development.
Each entry includes context, the decision made, and the rationale.

---

## [2026-06-04] Milestone 1 Scope Decisions

### DL-001 — Milestone 1 範圍以 `architecture.md` 為準

**Context:** `prd.md` 的「第一版要做」列出了收藏、應徵狀態、AI 摘要、AI 匹配度等功能，
但 `architecture.md` 的 Milestone 1 明確只包含職缺列表頁與詳情頁。

**Decision:** 以 `architecture.md` 定義的 Milestone 範圍為準。
PRD 描述的是整個 MVP 的完整功能集，architecture 則是每個 Milestone 的實作邊界。

**Rationale:** 避免第一次 commit 過度膨脹，確保可交付、可測試的最小可用版本。

---

### DL-002 — 收藏、應徵狀態、AI 功能移至 M2/M3

**Context:** PRD 的功能 5–8（收藏、應徵狀態、AI 摘要、AI 匹配度）對 M1 來說是非必要的。

**Decision:**
- Milestone 2：收藏功能 + 應徵狀態（使用 `SharedPreferences`）
- Milestone 3：AI 摘要（stub 實作） + AI 匹配度（本地技能比對）

**Rationale:** 分批交付降低複雜度，每個 Milestone 都有清楚的 acceptance criteria。

---

### DL-003 — 第一版只使用 `assets/mock/jobs.json`

**Context:** PRD 明確說明第一版使用本地 mock JSON，未來才改 API / crawler。

**Decision:** 職缺資料唯一來源為 `assets/mock/jobs.json`，由 `JobRepository`
透過 Flutter 的 `rootBundle` 載入。不使用 `Dio`，不接任何外部 API。

**Rationale:** 消除網路依賴，讓 M1 在任何環境下都能穩定執行。

---

### DL-004 — 不建立 `mock_jobs.dart`

**Context:** `architecture.md` 的資料夾結構圖列出了 `data/mock_jobs.dart`，
但 First Commit Task List 沒有這個檔案，資料流也只描述 JSON asset。

**Decision:** 不建立 `mock_jobs.dart`。Mock 資料統一放在 `assets/mock/jobs.json`。

**Rationale:** 資料放 JSON 讓格式更接近未來的真實 API response，也避免兩個資料源造成混淆。

---

### DL-005 — 不建立 `core/utils/extensions.dart`

**Context:** `architecture.md` 資料夾結構提到此檔案，但 Task List 未列出，M1 也沒有使用它的需求。

**Decision:** M1 不建立此檔案，待有實際 extension 需求時再建立。

**Rationale:** 避免建立空檔案增加雜訊。

---

### DL-006 — 搜尋使用 client-side filtering

**Context:** PRD 要求關鍵字搜尋，但 `architecture.md` 的 state 設計只示範 `fetchAll()`，
未定義搜尋如何實作。

**Decision:** M1 搜尋在 client-side 進行：`jobListProvider` 接受搜尋關鍵字參數，
對已載入的 mock data 做 in-memory 過濾（title / company）。

**Rationale:** Mock data 量小，client-side filtering 夠用；未來接真實 API 時再改為 server-side 搜尋。

---

### DL-007 — 不接真實 API、不做爬蟲、不做登入

**Context:** PRD 明確列出第一版不做的事項。

**Decision:** M1 不引入任何網路請求、爬蟲邏輯、或身份驗證機制。
`Dio` package 留在 pubspec 的備註中但不加入依賴，待 M2+ 再引入。

**Rationale:** 降低 M1 的依賴與測試複雜度，聚焦在 UI 與資料流的建立。
