# M5a — Navigation UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 重構 App 導航為 4-Tab BottomNavigationBar（ShellRoute），加入分頁（Pagination）、Kanban 追蹤頁、完整個人資料頁。

**Architecture:** GoRouter 改用 StatefulShellRoute；新增 JobListPaginatedNotifier 管理分頁；TrackerScreen 從 ApplyStatusNotifier 讀資料；UserProfile 擴充 bio/avatarPath/expectedSalary/expectedLocation。

**Tech Stack:** Flutter, go_router（現有）, Riverpod code-gen（現有）, appflowy_board, image_picker, cached_network_image, Freezed

**Branch:** `feature/m5-navigation-ux`

---

## File Structure

```
lib/
├── app/
│   ├── app.dart                          # MODIFY — 移除 ProviderScope（移到 main.dart）
│   ├── router.dart                       # REWRITE — StatefulShellRoute + 4 tabs
│   └── shell/
│       └── main_shell.dart               # NEW — BottomNavBar 殼
├── features/
│   ├── home/
│   │   └── presentation/screens/
│   │       └── home_screen.dart          # NEW — 暫時顯示最新職缺
│   ├── jobs/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── job_list_paginated_provider.dart  # NEW — 分頁 provider
│   │       └── screens/
│   │           └── explore_screen.dart   # NEW — JobListScreen 改版（分頁）
│   ├── tracker/
│   │   └── presentation/screens/
│   │       └── tracker_screen.dart       # NEW — Kanban 看板
│   └── profile/
│       ├── domain/
│       │   └── user_profile.dart         # MODIFY — 加 bio/avatarPath/expectedSalary/expectedLocation
│       └── presentation/
│           ├── providers/
│           │   └── user_profile_provider.dart  # (keep, update for new fields)
│           └── screens/
│               └── profile_screen.dart   # REWRITE — 完整個人資料
└── main.dart                             # MODIFY — 加 ProviderScope
```

---

## Task 1: 依賴安裝 + pubspec commit

**Files:** `pubspec.yaml`（已由 `flutter pub add` 更新）

- [ ] **Step 1: 確認套件已加入**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
Select-String "appflowy_board|image_picker|cached_network_image" pubspec.yaml
```

Expected：3 個套件都在 pubspec.yaml

- [ ] **Step 2: dart analyze 確認無錯**

```powershell
dart analyze lib/ 2>&1
```

Expected：`No issues found!`

- [ ] **Step 3: Commit**

```powershell
git add pubspec.yaml pubspec.lock
git commit -m "chore(m5a): add appflowy_board, image_picker, cached_network_image"
```

---

## Task 2: UserProfile 擴充 + build_runner

**Files:**
- Modify: `lib/features/profile/domain/user_profile.dart`
- Regenerate: `user_profile.freezed.dart`, `user_profile.g.dart`

- [ ] **Step 1: 更新 user_profile.dart**

覆寫 `C:\dev\career_pilot\lib\features\profile\domain\user_profile.dart`：

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default([]) List<String> skills,
    @Default('') String name,
    @Default('') String bio,
    String? avatarPath,
    @Default('') String expectedSalary,
    @Default('') String expectedLocation,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
```

- [ ] **Step 2: build_runner**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

Expected：`Built with build_runner in Ns; wrote N outputs.`

- [ ] **Step 3: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Expected：`No issues found!`

- [ ] **Step 4: flutter test（確認舊測試不 break）**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 5: Commit**

```powershell
git add lib/features/profile/domain/
git commit -m "feat(m5a): extend UserProfile with bio, avatarPath, expectedSalary, expectedLocation"
```

---

## Task 3: ShellRoute + BottomNavigationBar

**Files:**
- Create: `lib/app/shell/main_shell.dart`
- Rewrite: `lib/app/router.dart`
- Modify: `lib/main.dart`（加 ProviderScope）
- Create: `lib/features/home/presentation/screens/home_screen.dart`（暫時版）
- Create: `lib/features/tracker/presentation/screens/tracker_screen.dart`（骨架）

- [ ] **Step 1: 建立目錄**

```powershell
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\app\shell"
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\features\home\presentation\screens"
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\features\tracker\presentation\screens"
```

- [ ] **Step 2: 建立 MainShell（BottomNavBar 殼）**

建立 `C:\dev\career_pilot\lib\app\shell\main_shell.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.home_outlined,    activeIcon: Icons.home,    label: '首頁'),
    (icon: Icons.explore_outlined, activeIcon: Icons.explore, label: '探索'),
    (icon: Icons.work_outline,     activeIcon: Icons.work,    label: '追蹤'),
    (icon: Icons.person_outline,   activeIcon: Icons.person,  label: '我'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
```

- [ ] **Step 3: 建立暫時 HomeScreen**

建立 `C:\dev\career_pilot\lib\features\home\presentation\screens\home_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/presentation/providers/job_list_provider.dart';
import '../../../jobs/presentation/widgets/job_card.dart';
import '../../../jobs/presentation/widgets/job_card_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider());
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Pilot'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '今日推薦職缺',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) => ListView.builder(
                itemCount: jobs.take(10).length,
                padding: const EdgeInsets.only(bottom: 16),
                itemBuilder: (_, i) => JobCard(job: jobs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 建立 TrackerScreen 骨架（Task 5 完整實作）**

建立 `C:\dev\career_pilot\lib\features\tracker\presentation\screens\tracker_screen.dart`：

```dart
import 'package:flutter/material.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('求職追蹤')),
      body: const Center(child: Text('Kanban 看板即將上線')),
    );
  }
}
```

- [ ] **Step 5: 改寫 router.dart（StatefulShellRoute）**

覆寫 `C:\dev\career_pilot\lib\app\router.dart`：

```dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/jobs/presentation/screens/explore_screen.dart';
import '../features/jobs/presentation/screens/job_detail_screen.dart';
import '../features/tracker/presentation/screens/tracker_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import 'shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    // Full-screen routes (no BottomNavBar)
    GoRoute(
      path: '/jobs/:id',
      builder: (context, state) =>
          JobDetailScreen(jobId: state.pathParameters['id']!),
    ),

    // Shell (shows BottomNavBar)
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/explore',
            builder: (_, __) => const ExploreScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/tracker',
            builder: (_, __) => const TrackerScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
  ],
);
```

- [ ] **Step 6: dart analyze 修正所有錯誤**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart analyze lib/ 2>&1
```

注意：`ExploreScreen` 在 Task 4 建立，若此步驟報錯可先建立空 ExploreScreen。

暫時 ExploreScreen（`lib/features/jobs/presentation/screens/explore_screen.dart`）：

```dart
import 'package:flutter/material.dart';
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('探索')));
}
```

- [ ] **Step 7: flutter test**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 8: Commit**

```powershell
git add lib/app/ lib/features/home/ lib/features/tracker/ lib/features/jobs/presentation/screens/explore_screen.dart
git commit -m "feat(m5a): ShellRoute + BottomNavigationBar + 4 tab screens skeleton"
```

---

## Task 4: ExploreScreen — 分頁 + 下拉刷新 + 上拉載入

**Files:**
- Create: `lib/features/jobs/presentation/providers/job_list_paginated_provider.dart`
- Rewrite: `lib/features/jobs/presentation/screens/explore_screen.dart`

- [ ] **Step 1: 建立 JobListPaginatedNotifier**

建立 `C:\dev\career_pilot\lib\features\jobs\presentation\providers\job_list_paginated_provider.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/job_remote_datasource.dart';
import '../../data/job_repository.dart';
import '../../domain/job.dart';

part 'job_list_paginated_provider.g.dart';

@riverpod
class JobListPaginated extends _$JobListPaginated {
  static const _pageSize = 20;

  int _page = 1;
  bool _hasMore = true;
  List<Job> _allJobs = [];
  String _query = '';

  @override
  AsyncValue<List<Job>> build() => const AsyncData([]);

  bool get hasMore => _hasMore;

  Future<void> init({String query = ''}) async {
    _query = query;
    _page = 1;
    _hasMore = true;
    _allJobs = [];
    await _fetch();
  }

  Future<void> fetchMore() async {
    if (!_hasMore || state.isLoading) return;
    _page++;
    await _fetch(append: true);
  }

  Future<void> refresh({String query = ''}) async {
    await init(query: query.isNotEmpty ? query : _query);
  }

  Future<void> _fetch({bool append = false}) async {
    if (!append) state = const AsyncLoading();

    try {
      final client = ref.read(apiClientProvider);
      final ds = JobRemoteDataSource(client: client);
      final params = <String, dynamic>{
        'limit': _pageSize,
        'page': _page,
        if (_query.isNotEmpty) 'q': _query,
      };
      final data = await client.get('/api/v1/jobs', params: params);
      final items = (data['items'] as List<dynamic>?) ?? [];
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final newJobs = items
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();

      if (append) {
        _allJobs = [..._allJobs, ...newJobs];
      } else {
        _allJobs = newJobs;
      }

      _hasMore = _allJobs.length < total;
      state = AsyncData(List.unmodifiable(_allJobs));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
```

- [ ] **Step 2: build_runner**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

- [ ] **Step 3: 完整 ExploreScreen（分頁 + 篩選）**

覆寫 `C:\dev\career_pilot\lib\features\jobs\presentation\screens\explore_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorite_provider.dart';
import '../providers/job_list_paginated_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/job_card.dart';
import '../widgets/job_card_skeleton.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  bool _remoteOnly = false;
  bool _favOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobListPaginatedProvider.notifier).init();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(jobListPaginatedProvider.notifier).fetchMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(jobListPaginatedProvider.notifier).refresh(query: _query);
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    ref.read(jobListPaginatedProvider.notifier).refresh(query: value);
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobListPaginatedProvider);
    final notifier = ref.read(jobListPaginatedProvider.notifier);
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final colors = Theme.of(context).colorScheme;
    final sync = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('探索職缺'),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Sync button
          IconButton(
            icon: sync.status == SyncStatus.syncing
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync),
            tooltip: '同步職缺',
            onPressed: sync.status == SyncStatus.syncing
                ? null
                : () async {
                    await ref.read(syncNotifierProvider.notifier).sync();
                    if (mounted) _onRefresh();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜尋職缺或公司…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('遠端'),
                    selected: _remoteOnly,
                    selectedColor: colors.primaryContainer,
                    onSelected: (v) => setState(() => _remoteOnly = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('已收藏'),
                    selected: _favOnly,
                    selectedColor: colors.primaryContainer,
                    onSelected: (v) => setState(() => _favOnly = v),
                  ),
                ),
              ],
            ),
          ),
          // Job list
          Expanded(
            child: jobsAsync.when(
              loading: () => ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => const JobCardSkeleton(),
              ),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                var filtered = jobs;
                if (_remoteOnly) filtered = filtered.where((j) => j.isRemote).toList();
                if (_favOnly) filtered = filtered.where((j) => favIds.contains(j.id)).toList();

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length + (notifier.hasMore ? 1 : 0),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (_, i) {
                      if (i == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return JobCard(job: filtered[i]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Fix any issues.

- [ ] **Step 5: flutter test**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 6: Commit**

```powershell
git add lib/features/jobs/presentation/providers/job_list_paginated_provider.dart lib/features/jobs/presentation/providers/job_list_paginated_provider.g.dart lib/features/jobs/presentation/screens/explore_screen.dart
git commit -m "feat(m5a): paginated job list with infinite scroll and pull-to-refresh"
```

---

## Task 5: TrackerScreen — Kanban 看板

**Files:**
- Rewrite: `lib/features/tracker/presentation/screens/tracker_screen.dart`

- [ ] **Step 1: 完整 TrackerScreen 實作**

覆寫 `C:\dev\career_pilot\lib\features\tracker\presentation\screens\tracker_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/domain/job.dart';
import '../../../jobs/presentation/providers/apply_status_provider.dart';
import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';

/// Kanban column definition
const _columns = [
  (status: ApplyStatus.wantToApply, label: '想投',  color: Color(0xFF3B82F6)),
  (status: ApplyStatus.applied,     label: '已投',  color: Color(0xFFF59E0B)),
  (status: ApplyStatus.interview,   label: '面試',  color: Color(0xFF8B5CF6)),
  (status: ApplyStatus.rejected,    label: '結果',  color: Color(0xFF6B7280)),
];

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(jobListProvider());
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('求職追蹤'),
        elevation: 0,
      ),
      body: jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
        data: (jobs) {
          // Only show jobs that have an apply status
          final tracked = jobs.where((j) {
            final status = ref
                .read(applyStatusNotifierProvider(j.id))
                .valueOrNull;
            return status != null && status != ApplyStatus.none;
          }).toList();

          if (tracked.isEmpty) {
            return _EmptyTracker();
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            children: _columns.map((col) {
              final colJobs = tracked.where((j) {
                final status = ref
                    .read(applyStatusNotifierProvider(j.id))
                    .valueOrNull;
                return status == col.status;
              }).toList();

              return _KanbanColumn(
                label: col.label,
                color: col.color,
                status: col.status,
                jobs: colJobs,
                allJobs: tracked,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({
    required this.label,
    required this.color,
    required this.status,
    required this.jobs,
    required this.allJobs,
  });

  final String label;
  final Color color;
  final ApplyStatus status;
  final List<Job> jobs;
  final List<Job> allJobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<Job>(
      onAcceptWithDetails: (details) {
        ref
            .read(applyStatusNotifierProvider(details.data.id).notifier)
            .setStatus(status);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 220,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? color.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovered ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${jobs.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Job cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => _KanbanCard(job: jobs[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return LongPressDraggable<Job>(
      data: job,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 200,
          child: _CardContent(job: job, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _CardContent(job: job, isDragging: false),
      ),
      child: GestureDetector(
        onTap: () => context.push('/jobs/${job.id}'),
        child: _CardContent(job: job, isDragging: false),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.job, required this.isDragging});
  final Job job;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              job.company,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: colors.onSurfaceVariant),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    job.location,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTracker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.work_outline, size: 72,
                color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('還沒有追蹤中的職缺',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                )),
            const SizedBox(height: 8),
            Text('在職缺詳情頁設定應徵狀態\n職缺就會出現在這裡',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: dart analyze**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart analyze lib/ 2>&1
```

Fix any issues.

- [ ] **Step 3: Commit**

```powershell
git add lib/features/tracker/
git commit -m "feat(m5a): Kanban tracker screen with drag-and-drop"
```

---

## Task 6: ProfileScreen 完整改版

**Files:**
- Rewrite: `lib/features/profile/presentation/screens/profile_screen.dart`

- [ ] **Step 1: 完整 ProfileScreen 實作**

覆寫 `C:\dev\career_pilot\lib\features\profile\presentation\screens\profile_screen.dart`：

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../jobs/presentation/providers/apply_status_provider.dart';
import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';
import '../../../sync/presentation/providers/sync_provider.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _salaryCtrl.dispose();
    _locationCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  void _initControllers(profile) {
    if (_initialized) return;
    _nameCtrl.text = profile.name;
    _bioCtrl.text = profile.bio;
    _salaryCtrl.text = profile.expectedSalary;
    _locationCtrl.text = profile.expectedLocation;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      await ref.read(userProfileNotifierProvider.notifier)
          .setAvatarPath(image.path);
    }
  }

  void _saveField(String field, String value) {
    final notifier = ref.read(userProfileNotifierProvider.notifier);
    switch (field) {
      case 'name': notifier.setName(value);
      case 'bio': notifier.setBio(value);
      case 'salary': notifier.setExpectedSalary(value);
      case 'location': notifier.setExpectedLocation(value);
    }
  }

  void _addSkill() {
    final s = _skillCtrl.text.trim();
    if (s.isEmpty) return;
    ref.read(userProfileNotifierProvider.notifier).addSkill(s);
    _skillCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileNotifierProvider);
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    final jobsAsync = ref.watch(jobListProvider());
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sync = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('個人中心'), elevation: 0),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          _initControllers(profile);

          // Stats
          final jobs = jobsAsync.valueOrNull ?? [];
          int appliedCount = 0, interviewCount = 0;
          for (final j in jobs) {
            final s = ref.read(applyStatusNotifierProvider(j.id)).valueOrNull;
            if (s == ApplyStatus.applied || s == ApplyStatus.interview || s == ApplyStatus.rejected) {
              appliedCount++;
            }
            if (s == ApplyStatus.interview) interviewCount++;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar + Name ──────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: profile.avatarPath != null
                                ? FileImage(File(profile.avatarPath!))
                                : null,
                            child: profile.avatarPath == null
                                ? Icon(Icons.person, size: 48, color: colors.onPrimary)
                                : null,
                            backgroundColor: colors.primary,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: colors.primaryContainer,
                              child: Icon(Icons.camera_alt, size: 14, color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _EditableField(
                      controller: _nameCtrl,
                      hint: '你的名字',
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      onSubmitted: (v) => _saveField('name', v),
                    ),
                    const SizedBox(height: 4),
                    _EditableField(
                      controller: _bioCtrl,
                      hint: '一句話介紹自己…',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                      onSubmitted: (v) => _saveField('bio', v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Stats ────────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(label: '已收藏', value: '${favIds.length}', color: colors.primary),
                      _StatItem(label: '已投遞', value: '$appliedCount', color: const Color(0xFFF59E0B)),
                      _StatItem(label: '面試中', value: '$interviewCount', color: const Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── 求職偏好 ───────────────────────────────────
              _SectionTitle('求職偏好'),
              const SizedBox(height: 8),
              _LabeledField(
                icon: Icons.payments_outlined,
                label: '期望薪資',
                controller: _salaryCtrl,
                hint: '例：80K–120K',
                onSubmitted: (v) => _saveField('salary', v),
              ),
              const SizedBox(height: 8),
              _LabeledField(
                icon: Icons.location_on_outlined,
                label: '期望地點',
                controller: _locationCtrl,
                hint: '例：台北市、遠端',
                onSubmitted: (v) => _saveField('location', v),
              ),
              const SizedBox(height: 24),

              // ── 技能 ──────────────────────────────────────
              _SectionTitle('我的技能'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillCtrl,
                      decoration: const InputDecoration(hintText: '輸入技能…'),
                      onSubmitted: (_) => _addSkill(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _addSkill, child: const Text('新增')),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: profile.skills.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => ref.read(userProfileNotifierProvider.notifier).removeSkill(s),
                  backgroundColor: colors.primaryContainer,
                  labelStyle: TextStyle(color: colors.onPrimaryContainer),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // ── 設定 ──────────────────────────────────────
              _SectionTitle('設定'),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('同步職缺'),
                subtitle: sync.lastSyncTime != null
                    ? Text('上次：${_fmtTime(sync.lastSyncTime!)}')
                    : const Text('尚未同步'),
                trailing: sync.status == SyncStatus.syncing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.chevron_right),
                onTap: sync.status == SyncStatus.syncing
                    ? null
                    : () => ref.read(syncNotifierProvider.notifier).sync(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('關於 Career Pilot'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Career Pilot',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmtTime(DateTime t) =>
      '${t.month}/${t.day} ${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
}

// ── Supporting widgets ───────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.controller, required this.hint,
    this.textAlign = TextAlign.start,
    this.style, required this.onSubmitted,
  });
  final TextEditingController controller;
  final String hint;
  final TextAlign textAlign;
  final TextStyle? style;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        textAlign: textAlign,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          filled: false,
        ),
        onSubmitted: onSubmitted,
      );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.icon, required this.label, required this.controller,
    required this.hint, required this.onSubmitted,
  });
  final IconData icon;
  final String label, hint;
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(hintText: hint, border: InputBorder.none, filled: false),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      );
}
```

- [ ] **Step 2: 更新 UserProfileNotifier — 新增 setAvatarPath / setBio / setExpectedSalary / setExpectedLocation**

讀取 `lib/features/profile/presentation/providers/user_profile_provider.dart`，在 `addSkill` 方法下方加入：

```dart
  Future<void> setBio(String bio) async {
    final profile = await future;
    await _save(profile.copyWith(bio: bio));
  }

  Future<void> setAvatarPath(String path) async {
    final profile = await future;
    await _save(profile.copyWith(avatarPath: path));
  }

  Future<void> setExpectedSalary(String salary) async {
    final profile = await future;
    await _save(profile.copyWith(expectedSalary: salary));
  }

  Future<void> setExpectedLocation(String location) async {
    final profile = await future;
    await _save(profile.copyWith(expectedLocation: location));
  }
```

- [ ] **Step 3: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Fix any issues.

- [ ] **Step 4: flutter test**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 5: Commit**

```powershell
git add lib/features/profile/
git commit -m "feat(m5a): complete profile screen with stats, avatar, and preferences"
```

---

## Task 7: 最終驗收 + CLAUDE.md + merge

- [ ] **Step 1: dart analyze**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart analyze lib/ 2>&1
```

Expected：`No issues found!`

- [ ] **Step 2: flutter test**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 3: 更新 CLAUDE.md Milestone Roadmap**

在 CLAUDE.md 的 Milestone Roadmap 加入：
```
| **M5a** | ✅ 完成 | BottomNavBar、Pagination、Kanban 追蹤、完整 Profile | `dev` |
```

- [ ] **Step 4: Commit docs**

```powershell
git add CLAUDE.md
git commit -m "docs(m5a): update CLAUDE.md milestone roadmap"
```

- [ ] **Step 5: merge → dev**

```powershell
git checkout dev
git merge --no-ff feature/m5-navigation-ux -m "feat(m5a): BottomNavBar, pagination, Kanban, full ProfileScreen"
git checkout feature/m5-navigation-ux
git log --oneline -8
```

---

## 驗收標準

- [ ] `dart analyze lib/` → No issues
- [ ] `flutter test` → All passed
- [ ] App 顯示 4-Tab BottomNavigationBar
- [ ] 探索頁初始顯示 20 筆，上拉自動載入更多
- [ ] 下拉重新整理重設資料
- [ ] 追蹤頁顯示有應徵狀態的職缺，分 4 欄
- [ ] 拖拉卡片更新狀態並持久化
- [ ] Profile 可編輯 name/bio/salary/location，頭像可選取
- [ ] 統計數字（收藏/已投/面試）正確
