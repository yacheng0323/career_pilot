# M5 — Navigation UX 重設計 Design Spec
**Date:** 2026-06-05
**Status:** Approved — ready for implementation plan
**Branch:** `feature/m5-navigation-ux`

---

## Goal

重構 App 導航架構，從單一列表頁升級為 4-Tab BottomNavigationBar，
新增首頁 Swipe 卡片體驗、Kanban 求職追蹤、完整個人資料頁，
並加入 Infinite Scroll 分頁功能取代一次性全量載入。

---

## 執行策略：方案 B（分兩波）

### M5a — 架構地基（本次實作）
- BottomNavigationBar + ShellRoute（4 Tab）
- 分頁（Pagination）+ 下拉刷新 + 上拉載入更多
- 📋 追蹤頁（Kanban 看板）
- 👤 我（完整個人資料）

### M5b — 首頁體驗（下一 Milestone）
- 🏠 首頁（Swipe 卡片流）
- 🔍 探索頁微調

---

## 導航架構

### Router（GoRouter ShellRoute）

```
StatefulShellRoute（BottomNavBar 殼）
├── /home       → HomeScreen（M5b，暫時顯示最新職缺列表）
├── /explore    → ExploreScreen（現 JobListScreen，加分頁）
├── /tracker    → TrackerScreen（Kanban 看板）
└── /profile    → ProfileScreen（完整個人資料）

Full-screen（覆蓋 NavBar）
└── /jobs/:id   → JobDetailScreen
```

### BottomNavigationBar

| Index | Icon | Label | Screen |
|-------|------|-------|--------|
| 0 | `home` | 首頁 | HomeScreen |
| 1 | `explore` | 探索 | ExploreScreen |
| 2 | `work` | 追蹤 | TrackerScreen |
| 3 | `person` | 我 | ProfileScreen |

---

## 頁面設計

### 🏠 首頁（HomeScreen）— M5a 簡版

M5a 暫時顯示「最新 10 筆職缺」列表 + Hero 標語。
M5b 升級為 Swipe 卡片流（`flutter_card_swiper`）。

### 🔍 探索（ExploreScreen）

現有 `JobListScreen` 功能搬移，改造重點：
- 分頁：`JobListPaginatedNotifier`，每頁 20 筆
- 上拉載入更多：`ScrollController` 偵測底部 200px 觸發
- 下拉刷新：`RefreshIndicator` 重設 page=1
- 搜尋 + 篩選 chips 保留
- AppBar Sync 按鈕移除（移至 Profile 頁）

### 📋 追蹤（TrackerScreen）— Kanban

4 欄橫向捲動看板：

```
┌──────┬──────┬──────┬──────┐
│ 想投  │ 已投  │ 面試  │ 結果  │
│  (N) │  (N) │  (N) │  (N) │
├──────┼──────┼──────┼──────┤
│ Card │ Card │ Card │      │
│ Card │      │      │      │
└──────┴──────┴──────┴──────┘
```

- 資料來源：`ApplyStatusNotifier`（現有 SharedPreferences）
- 每欄顯示該狀態的所有已收藏/已投職缺
- 長按卡片 → 拖到其他欄 → `setStatus()` 更新
- 點卡片 → `context.push('/jobs/:id')`
- 套件：`appflowy_board ^0.1.4`（或自製 `DragTarget` 實作）

ApplyStatus mapping：
```dart
ApplyStatus.wantToApply → "想投" 欄
ApplyStatus.applied     → "已投" 欄
ApplyStatus.interview   → "面試" 欄
ApplyStatus.rejected    → "結果" 欄
```

### 👤 我（ProfileScreen）— 完整個人資料

```
頭像（image_picker）+ 姓名 + 一句話自介
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 技能（現有 chips）
💰 期望薪資（TextField）
📍 期望地點（TextField）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 求職統計（讀取 SharedPreferences 計算）
   收藏 N 筆 │ 已投 N 筆 │ 面試 N 次
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚙️ 設定
   深色模式切換（ThemeMode override）
   ↻ 同步職缺（現 AppBar Sync 按鈕）
   關於 App
```

---

## 資料模型變更

### UserProfile（擴充 Freezed model）

```dart
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default([]) List<String> skills,     // 現有
    @Default('') String name,             // 現有
    @Default('') String bio,              // NEW 一句話自介
    String? avatarPath,                   // NEW 本機頭像路徑
    @Default('') String expectedSalary,   // NEW 期望薪資
    @Default('') String expectedLocation, // NEW 期望地點
  }) = _UserProfile;
  factory UserProfile.fromJson(...) => ...;
}
```

### 分頁 Provider（新）

```dart
@riverpod
class JobListPaginated extends _$JobListPaginated {
  static const _pageSize = 20;
  int _page = 1;
  bool _hasMore = true;
  List<Job> _jobs = [];

  @override
  AsyncValue<List<Job>> build({String query = ''}) => const AsyncData([]);

  Future<void> fetchMore();  // 上拉觸發
  Future<void> refresh();    // 下拉觸發，reset page=1
  bool get hasMore => _hasMore;
}
```

---

## 新增套件

| 套件 | 版本 | 用途 |
|------|------|------|
| `appflowy_board` | `^0.1.4` | Kanban 拖拉看板 |
| `image_picker` | `^1.1.2` | 頭像選取（相機/相簿）|
| `cached_network_image` | `^3.4.1` | 頭像本機快取顯示 |

> `flutter_card_swiper` 留到 M5b（首頁 Swipe）再加。

---

## 不在範圍（YAGNI）

- M5b Swipe 首頁（下一 Milestone）
- 推播通知
- 帳號系統
- 頭像上傳雲端（只存本機路徑）
- Kanban 卡片拖拉動畫細緻優化（M5b 可選）

---

## Acceptance Criteria

1. App 啟動後顯示 BottomNavigationBar，4 個 Tab 可切換
2. 探索頁每次載入 20 筆，上拉自動載入下一頁，下拉重整
3. 追蹤頁顯示所有有應徵狀態的職缺，分 4 欄
4. 拖拉卡片到其他欄後，狀態即時更新並持久化
5. 個人資料頁可編輯 name、bio、skills、expectedSalary、expectedLocation
6. 頭像可從相簿選取，顯示圓形裁剪
7. Profile 統計數字正確反映收藏與應徵數量
8. `dart analyze lib/` → No issues
9. `flutter test` → All passed
