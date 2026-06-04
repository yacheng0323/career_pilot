# Milestone 3 — Advanced Filters + AI Summary + Match Score

## Goal

完成 PRD 剩餘功能：技能/地點篩選、使用者技能檔案、AI 職缺摘要（3 點）、AI 匹配度分析。
AI 功能使用 Claude API (dart anthropic package)；首版以 mock 回應保護 API quota，
可透過 env flag 切換真實呼叫。

---

## Scope

| In scope | Out of scope |
|---|---|
| 技能 filter chip（multi-select）| 真實爬蟲 / 後端 |
| 地點 filter（文字下拉）| 登入 / 帳號 |
| UserProfileNotifier — 儲存使用者技能清單 | 推播 |
| UserProfile 設定頁（/profile） | M4 功能 |
| AI 摘要 card（detail 頁，3 bullet）| |
| AI 匹配度 badge（detail 頁，百分比 + 說明）| |
| AiService — 封裝 Claude API 呼叫 | |
| mock mode（env `USE_MOCK_AI=true`）| |
| `test/m3_test.dart` — filter logic + mock AI | |

---

## Task Checklist

- [x] `pubspec.yaml` — add `anthropic_sdk_dart` (or http + dart:convert)
- [x] `lib/core/ai/ai_service.dart` — Claude API wrapper (summary + match)
- [x] `lib/features/profile/domain/user_profile.dart` — Freezed model
- [x] `lib/features/profile/presentation/providers/user_profile_provider.dart`
- [x] `lib/features/profile/presentation/screens/profile_screen.dart`
- [x] `lib/app/router.dart` — add `/profile` route + AppBar action
- [x] `lib/features/jobs/presentation/screens/job_list_screen.dart` — skill + location filters
- [x] `lib/features/jobs/presentation/screens/job_detail_screen.dart` — AI summary + match card
- [x] `dart analyze lib/` — zero errors
- [x] `test/m3_test.dart` — filter logic + AiService mock tests

---

## Acceptance Criteria

1. 技能 filter chip 正確過濾職缺（多選 OR 邏輯）
2. 地點 filter 正確過濾
3. Profile 頁可新增/刪除使用者技能，資料持久化
4. 詳情頁顯示 AI 3-bullet 摘要（mock 可，API ready）
5. 詳情頁顯示匹配度分數與說明
6. `dart analyze lib/` zero errors
7. M3 tests pass
