# Milestone 2 — Favorites + Apply Status

## Goal

Add local persistence for job favorites and application status tracking.
Users can bookmark jobs, mark apply progress, and filter the list by remote/favorited.
No real API — all state lives in `SharedPreferences`.

---

## Scope

| In scope | Out of scope |
|---|---|
| `shared_preferences ^2.3` dependency | Real API / Dio |
| `FavoriteNotifier` — toggle & persist favorite job IDs | Auth / login |
| Bookmark icon on `JobCard` | AI match score |
| `ApplyStatusNotifier` — state machine (想投/已投/面試/已拒絕) | Push notifications |
| Apply status selector on `JobDetailScreen` | M3 features |
| Filter chip row on `JobListScreen` (遠端 / 已收藏) | |
| `core/persistence/` layer (shared_preferences wrappers) | |

---

## Task Checklist

- [x] `pubspec.yaml` — uncomment `shared_preferences ^2.3`
- [x] `lib/core/persistence/persistence_service.dart` — SharedPreferences wrapper
- [x] `lib/features/jobs/presentation/providers/favorite_provider.dart` — FavoriteNotifier
- [x] `lib/features/jobs/presentation/providers/apply_status_provider.dart` — ApplyStatusNotifier + ApplyStatus enum
- [x] `lib/features/jobs/presentation/widgets/job_card.dart` — add bookmark IconButton
- [x] `lib/features/jobs/presentation/screens/job_list_screen.dart` — add filter chip row
- [x] `lib/features/jobs/presentation/screens/job_detail_screen.dart` — add apply status selector
- [x] `dart analyze lib/` — zero errors gate
- [x] `test/m2_widget_test.dart` — FavoriteNotifier + ApplyStatusNotifier unit tests

---

## Files to Create / Modify

### New files
| Path | Purpose |
|---|---|
| `lib/core/persistence/persistence_service.dart` | SharedPreferences read/write helpers |
| `lib/features/jobs/presentation/providers/favorite_provider.dart` | FavoriteNotifier |
| `lib/features/jobs/presentation/providers/apply_status_provider.dart` | ApplyStatusNotifier + enum |
| `test/m2_widget_test.dart` | Unit tests for M2 providers |

### Modified files
| Path | Change |
|---|---|
| `pubspec.yaml` | Uncomment shared_preferences |
| `lib/features/jobs/presentation/widgets/job_card.dart` | Add bookmark icon |
| `lib/features/jobs/presentation/screens/job_list_screen.dart` | Add filter chips |
| `lib/features/jobs/presentation/screens/job_detail_screen.dart` | Add apply status dropdown |

---

## Acceptance Criteria

1. Tapping the bookmark icon on a JobCard toggles favorite; survives hot restart
2. Apply status chip on detail screen cycles through 4 states; survives hot restart
3. Filter chips on list screen correctly narrow the job list
4. `dart analyze lib/` — zero errors
5. M2 unit tests pass
