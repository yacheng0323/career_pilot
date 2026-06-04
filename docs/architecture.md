# AI Job Finder App — Architecture

## MVP Scope (Milestone 1)

Milestone 1 delivers exactly two screens with mock data, no real API, no auth:

| In scope | Out of scope |
|---|---|
| Job list screen (search bar + cards) | Login / auth |
| Job detail screen (content, skills, company) | Real crawler / API |
| Riverpod state for job list | Favorites / apply status |
| GoRouter navigation | AI summary / match score |
| Mock JSON data source | Push notifications |

Milestones 2+ will layer in: favorites, apply status, AI summary, AI match score, and eventually real API.

---

## Folder Structure (feature-first)

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  # MaterialApp + ProviderScope
│   └── router.dart               # GoRouter route definitions
│
├── core/
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       └── extensions.dart       # misc Dart extensions
│
├── features/
│   ├── jobs/
│   │   ├── data/
│   │   │   ├── mock_jobs.dart    # raw mock JSON list
│   │   │   └── job_repository.dart
│   │   ├── domain/
│   │   │   └── job.dart          # Freezed model
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── job_list_provider.dart
│   │       ├── screens/
│   │       │   ├── job_list_screen.dart
│   │       │   └── job_detail_screen.dart
│   │       └── widgets/
│   │           ├── job_card.dart
│   │           └── skill_chip.dart
│
└── assets/
    └── mock/
        └── jobs.json
```

> `assets/` lives at the project root (sibling of `lib/`), registered in `pubspec.yaml`.

---

## Data Flow

```
MockJobsSource (JSON)
       │
       ▼
 JobRepository          ← pure Dart, no Flutter dep
       │
       ▼
 jobListProvider        ← Riverpod AsyncNotifierProvider
       │
       ▼
 JobListScreen          ← ConsumerWidget
       │  (tap card)
       ▼
 GoRouter → /jobs/:id
       │
       ▼
 JobDetailScreen        ← reads job by id from same provider
```

---

## Key Dependencies

| Package | Version pin | Purpose |
|---|---|---|
| `flutter_riverpod` | `^2.6` | State management |
| `riverpod_annotation` | `^2.6` | Code-gen annotations |
| `freezed_annotation` | `^2.4` | Immutable models |
| `freezed` (dev) | `^2.5` | Freezed code-gen |
| `json_serializable` (dev) | `^6.8` | JSON ↔ model |
| `build_runner` (dev) | `^2.4` | Code generation |
| `go_router` | `^14.0` | Navigation |
| `shared_preferences` | `^2.3` | Local persistence (M2+) |
| `dio` | `^5.7` | Reserved for future API |

---

## Routing (GoRouter)

| Path | Screen | Notes |
|---|---|---|
| `/` | `JobListScreen` | initial location |
| `/jobs/:id` | `JobDetailScreen` | `id` = job.id string |

---

## State Design

```dart
// Milestone 1 — simple read-only provider
@riverpod
Future<List<Job>> jobList(JobListRef ref) async {
  return JobRepository().fetchAll();
}
```

Milestone 2 adds `AsyncNotifier` for favorites + apply status via `SharedPreferences`.

---

## Job Model (Freezed)

```dart
@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required String title,
    required String company,
    required String location,
    required bool isRemote,
    required String salaryRange,
    required List<String> skills,
    required String description,
    required String source,       // e.g. "LinkedIn", "104"
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

---

## Implementation Plan

### Milestone 1 — List + Detail (this commit)

1. Add packages to `pubspec.yaml`, run `flutter pub get`
2. Create `Job` Freezed model + run `build_runner`
3. Create `assets/mock/jobs.json` with 5–8 sample jobs
4. Create `JobRepository` (reads mock JSON via `rootBundle`)
5. Create `jobListProvider` (Riverpod)
6. Wire up `GoRouter` in `app/router.dart`
7. Build `JobListScreen` (search bar + `ListView` of `JobCard`)
8. Build `JobDetailScreen` (title, company, description, skill chips)
9. Replace boilerplate `main.dart` with `ProviderScope` + `app.dart`
10. Run `flutter analyze` — zero issues gate

### Milestone 2 — Favorites + Apply Status

- Add `SharedPreferences` persistence layer
- `FavoriteNotifier`, `ApplyStatusNotifier`
- Bookmark icon on `JobCard` and detail screen
- Filter chip row on `JobListScreen`

### Milestone 3 — AI Features (mock)

- Stub AI service returning hardcoded 3-bullet summary
- Match score calculated locally from skill overlap %
- UI: expandable summary card + match badge on detail screen

---

## First Commit Task List

- [ ] `pubspec.yaml` — add all M1 dependencies
- [ ] `lib/app/app.dart` — `ProviderScope` + `MaterialApp.router`
- [ ] `lib/app/router.dart` — GoRouter with `/` and `/jobs/:id`
- [ ] `lib/core/theme/app_theme.dart` — `ThemeData` seed color
- [ ] `lib/features/jobs/domain/job.dart` — Freezed model
- [ ] `lib/features/jobs/data/job_repository.dart` — loads JSON asset
- [ ] `assets/mock/jobs.json` — 6 mock job entries
- [ ] `pubspec.yaml` assets section — register `assets/mock/`
- [ ] `lib/features/jobs/presentation/providers/job_list_provider.dart`
- [ ] `lib/features/jobs/presentation/screens/job_list_screen.dart`
- [ ] `lib/features/jobs/presentation/widgets/job_card.dart`
- [ ] `lib/features/jobs/presentation/screens/job_detail_screen.dart`
- [ ] `lib/features/jobs/presentation/widgets/skill_chip.dart`
- [ ] `lib/main.dart` — entry point calling `app.dart`
- [ ] Run `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Run `flutter analyze` — must pass with zero errors
