# M4c 設計：備忘錄 + 面試日期提醒（整合 Kanban）

**日期：** 2026-07-02
**狀態：** 已定案

## 目標

完成 Milestone Roadmap 最後一項 M4c：
1. 每個職缺可寫**備忘錄**（自由文字）
2. 每個職缺可設**面試日期**，Tracker 看板顯示提醒
3. 一併清償後端技術債 P1（skills filter DB-side）與 P2（`_upsert_jobs` 欄位不完整）

## Flutter 設計

### 資料模型與持久化

- `JobMemo`：`{ note: String, interviewAt: DateTime? }`
- 持久化：SharedPreferences，key = `job_memo_<jobId>`，值為 JSON 字串
  （與 `apply_status_<jobId>`、favorite 同一套 PersistenceService 模式）
- Provider：`JobMemoNotifier`（`@riverpod` family per jobId），API：
  - `build(jobId)` → 讀 prefs，無資料回傳空 memo
  - `setNote(String)`、`setInterviewDate(DateTime?)` — 立即寫入 prefs
  - note 與 interviewAt 都為空 → 移除 key

### UI

1. **JobDetailScreen** 新增 `_MemoCard`（應徵狀態下方）：
   - 多行 TextField（備忘錄），失焦/按儲存時寫入
   - 面試日期列：`showDatePicker` + `showTimePicker`，可清除
2. **TrackerScreen**：
   - Kanban 卡片：有 interviewAt 時顯示日期 chip
     - 已過期 → 灰色；3 天內 → 紅色；7 天內 → 橘色；其他 → 藍色
   - 看板頂部 `_UpcomingBanner`：列出未來 7 天內有面試的職缺（依日期排序）

### 提醒範圍決策

**不做** OS 推播（flutter_local_notifications 需平台設定、權限，超出 side-project 範圍）。
提醒 = Tracker 內 banner + 卡片色彩 chip（in-app reminder）。

## Backend 技術債

### P1：Skills filter 移到 DB-side

- skills 欄位為 JSON 字串（如 `'["Python", "SQL"]'`）
- 改用 `Job.skills.ilike('%"<skill>"%')`，多個 skill 用 OR 串接
- 引號錨定避免 `java` 誤中 `javascript`；ilike 保持大小寫不敏感
- 分頁改全 DB-side：`func.count()` 取 total，`offset/limit` 取分頁

### P2：`_upsert_jobs` 更新完整欄位

- 更新時一併覆蓋 `company`、`location`、`is_remote`、`url`

## 測試計畫

| 層 | 新增測試 |
|----|---------|
| Backend | skills DB-side（大小寫、引號錨定不誤中）、分頁 total 正確、upsert 覆蓋 location/company/url/is_remote |
| Flutter | JobMemoNotifier（讀寫/清除/JSON roundtrip）、日期急迫度 helper、MemoCard widget |

全部既有測試（Flutter 49 + Backend 29）必須保持綠燈。
