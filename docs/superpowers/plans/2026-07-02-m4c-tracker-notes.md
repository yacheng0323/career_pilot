# M4c 實作計畫：備忘錄 + 面試提醒 + 後端技術債

**Spec：** `docs/superpowers/specs/2026-07-02-m4c-tracker-notes-design.md`
**分支：** `feature/m4c-tracker-notes`（自 `dev` 分出）

## Task 0：分支整理
- [ ] `feature/m6-polish`（deploy fix + CLAUDE.md）merge --no-ff 回 `dev`
- [ ] 從 `dev` 開 `feature/m4c-tracker-notes`

## Task 1：Backend P1 — skills filter DB-side（TDD）
- [ ] 紅：`test_api_jobs.py` 新增測試 — `java` 不誤中 `javascript`、大小寫不敏感、
      skills + 分頁 total 正確
- [ ] 綠：`routers/jobs.py` 改 `ilike('%"<skill>"%')` OR 串接 + `func.count()` + DB offset/limit
- [ ] pytest 全綠

## Task 2：Backend P2 — `_upsert_jobs` 完整欄位（TDD）
- [ ] 紅：`test_sync.py` 新增測試 — 更新時覆蓋 company/location/is_remote/url
- [ ] 綠：`scheduler.py` 補欄位
- [ ] pytest 全綠

## Task 3：Flutter — JobMemo 模型與 Provider（TDD）
- [ ] 紅：`test/m4c_test.dart` — JobMemoNotifier 讀寫/清除/roundtrip、
      `interviewUrgency()` helper（過期/3天/7天/更遠）
- [ ] 綠：`lib/features/tracker/domain/job_memo.dart` +
      `lib/features/tracker/presentation/providers/job_memo_provider.dart`
- [ ] `dart run build_runner build`、`flutter test` 全綠

## Task 4：Flutter UI
- [ ] JobDetailScreen `_MemoCard`（備忘錄 TextField + 面試日期 picker）
- [ ] TrackerScreen 卡片日期 chip + `_UpcomingBanner`
- [ ] MemoCard widget test
- [ ] `dart analyze lib/` zero issues、`flutter test` 全綠

## Task 5：文件與收尾
- [ ] CLAUDE.md：M4c ✅、測試數更新、技術債表清償項移除
- [ ] commit docs、merge 回 `dev`、`dev` → `main`、push

## 驗證關卡（每 task）
`pytest -q` / `flutter test` / `dart analyze lib/` 需有實際執行輸出證據。
