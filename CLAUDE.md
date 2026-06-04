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

### Data flow

```
assets/mock/jobs.json
    → JobRepository (rootBundle)
    → jobListProvider (Riverpod FutureProvider)
    → JobListScreen (ConsumerStatefulWidget)
        → tap → GoRouter /jobs/:id → JobDetailScreen
            → _aiAnalysisProvider (FutureProvider.family)
                → AiService.analyze(jobSkills, userSkills)
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

### AI service (`lib/core/ai/ai_service.dart`)

`AiService` defaults to **mock mode** when `kDebugMode == true` (i.e. every `flutter run` without `--release`). Mock mode calculates match score from skill overlap without any network call. Pass `CLAUDE_API_KEY` via `--dart-define` to enable real Claude API calls in any build mode.

### Code generation

The following files are **generated — do not edit manually**:
- `*.freezed.dart` — Freezed immutable model implementations
- `*.g.dart` — `json_serializable` + `riverpod_generator` output

Trigger re-generation whenever you add/change a `@freezed` class or `@riverpod` provider.

---

## Testing

Tests live in `test/`:

| File | What it covers |
|------|----------------|
| `widget_test.dart` | `SkillChip` + `JobCard` widget rendering (M1) |
| `m2_widget_test.dart` | `FavoriteNotifier` + `ApplyStatusNotifier` unit tests (M2) |
| `m3_test.dart` | Filter logic, `AiService` mock, `UserProfileNotifier` (M3) |

All provider tests use `ProviderContainer` + `SharedPreferences.setMockInitialValues({})` — no Flutter widget pump needed.
