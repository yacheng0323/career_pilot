# M5b — Swipe 首頁 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 將首頁升級為 Tinder 式 Swipe 卡片體驗：右滑收藏、左滑跳過，卡片用完自動補充，底部顯示操作提示按鈕。

**Architecture:** `HomeScreen` 使用 `flutter_card_swiper`；新增 `SwipeJobNotifier`（Riverpod）管理卡片池（從 `jobListProvider` 取資料並維護已滑過的 index）；Swipe 動作直接呼叫 `FavoriteNotifier.toggle()`。

**Tech Stack:** flutter_card_swiper（已安裝）, Riverpod（現有）

**Branch:** `feature/m5-navigation-ux`

---

## File Structure

```
lib/
├── features/
│   └── home/
│       └── presentation/
│           ├── providers/
│           │   └── swipe_job_provider.dart      # NEW — 管理 swipe 卡片池
│           ├── screens/
│           │   └── home_screen.dart             # REWRITE — Swipe UI
│           └── widgets/
│               └── swipe_job_card.dart          # NEW — 大張 swipe 卡片
```

---

## Task 1: SwipeJobNotifier + 依賴 commit

**Files:**
- Create: `lib/features/home/presentation/providers/swipe_job_provider.dart`

- [ ] **Step 1: 建立目錄**

```powershell
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\features\home\presentation\providers"
New-Item -ItemType Directory -Force "C:\dev\career_pilot\lib\features\home\presentation\widgets"
```

- [ ] **Step 2: 建立 swipe_job_provider.dart**

建立 `C:\dev\career_pilot\lib\features\home\presentation\providers\swipe_job_provider.dart`：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/jobs/domain/job.dart';
import '../../../../features/jobs/presentation/providers/job_list_provider.dart';

part 'swipe_job_provider.g.dart';

/// Manages the deck of jobs for the swipe home screen.
/// Maintains a circular pool so the user always has cards to swipe.
@riverpod
class SwipeJobDeck extends _$SwipeJobDeck {
  static const _deckSize = 15;

  @override
  AsyncValue<List<Job>> build() {
    // Watch source jobs and rebuild deck when they change
    final jobsAsync = ref.watch(jobListProvider());
    return jobsAsync.whenData((jobs) => jobs.take(_deckSize).toList());
  }

  /// Called when a card is swiped away.
  /// Removes the swiped card from the front and appends the next unseen card.
  void onSwiped(int index) {
    final jobs = state.valueOrNull;
    if (jobs == null || jobs.isEmpty) return;

    final sourceJobs = ref.read(jobListProvider()).valueOrNull ?? [];
    final remaining = List<Job>.from(jobs)..removeAt(index);

    // Find next job not already in deck
    final inDeck = remaining.map((j) => j.id).toSet();
    final next = sourceJobs.firstWhere(
      (j) => !inDeck.contains(j.id),
      orElse: () => sourceJobs.first, // wrap around if exhausted
    );

    remaining.add(next);
    state = AsyncData(remaining);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
```

- [ ] **Step 3: build_runner**

```powershell
$env:PATH = "D:\flutter\bin;$env:PATH"
cd C:\dev\career_pilot
dart run build_runner build --delete-conflicting-outputs 2>&1 | Select-Object -Last 5
```

- [ ] **Step 4: dart analyze**

```powershell
dart analyze lib/ 2>&1
```

Expected：`No issues found!`

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock lib/features/home/presentation/providers/
git commit -m "feat(m5b): add SwipeJobDeck provider and flutter_card_swiper dep"
```

---

## Task 2: SwipeJobCard widget

**Files:**
- Create: `lib/features/home/presentation/widgets/swipe_job_card.dart`

- [ ] **Step 1: 建立 SwipeJobCard**

建立 `C:\dev\career_pilot\lib\features\home\presentation\widgets\swipe_job_card.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../jobs/domain/job.dart';
import '../../../jobs/presentation/widgets/skill_chip.dart';

/// Full-size card used in the Swipe home screen.
class SwipeJobCard extends StatelessWidget {
  const SwipeJobCard({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header band ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source badge
                  _SourceChip(source: job.source),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    job.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Company
                  Text(
                    job.company,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.location_on_outlined,
                          label: job.location,
                        ),
                        _MetaChip(
                          icon: Icons.payments_outlined,
                          label: job.salaryRange.isEmpty ? '薪資面議' : job.salaryRange,
                        ),
                        if (job.isRemote)
                          _MetaChip(
                            icon: Icons.wifi_outlined,
                            label: '遠端',
                            highlighted: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Skills
                    if (job.skills.isNotEmpty) ...[
                      Text(
                        '所需技能',
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job.skills
                            .take(6)
                            .map((s) => SkillChip(label: s))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description preview
                    Expanded(
                      child: Text(
                        job.description,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.5,
                        ),
                        overflow: TextOverflow.fade,
                      ),
                    ),

                    // Tap hint
                    Center(
                      child: Text(
                        '點擊查看完整職缺',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────

/// 來源顏色對應（與 JobCard 保持一致）
const _sourceConfig = {
  '104':       (label: '104人力銀行', color: Color(0xFFFF6B00)),
  'yourator':  (label: 'Yourator',   color: Color(0xFF00A86B)),
  'remotive':  (label: 'Remotive',   color: Color(0xFF7C3AED)),
  'arbeitnow': (label: 'Arbeitnow',  color: Color(0xFF2563EB)),
};

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final cfg = _sourceConfig[source.toLowerCase()];
    final label = cfg?.label ?? source;
    final color = cfg?.color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });
  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = highlighted ? colors.tertiary : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: highlighted ? FontWeight.w600 : null,
              ),
        ),
      ],
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

- [ ] **Step 3: Commit**

```powershell
git add lib/features/home/presentation/widgets/swipe_job_card.dart
git commit -m "feat(m5b): add SwipeJobCard large card widget"
```

---

## Task 3: HomeScreen — Swipe UI

**Files:**
- Rewrite: `lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: 覆寫 HomeScreen**

覆寫 `C:\dev\career_pilot\lib\features\home\presentation\screens\home_screen.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../../jobs/presentation/widgets/job_card_skeleton.dart';
import '../providers/swipe_job_provider.dart';
import '../widgets/swipe_job_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _onSwipe(int prevIndex, int? currentIndex, CardSwiperDirection direction) {
    final deck = ref.read(swipeJobDeckProvider).valueOrNull;
    if (deck == null || deck.isEmpty) return false;

    final job = deck[prevIndex % deck.length];

    if (direction == CardSwiperDirection.right) {
      // Right swipe → favorite
      ref.read(favoriteNotifierProvider.notifier).toggle(job.id);
      _showSwipeSnack(context, '❤️ 已收藏 ${job.title}', Colors.pink);
    } else if (direction == CardSwiperDirection.left) {
      // Left swipe → skip (no state change)
      _showSwipeSnack(context, '跳過', Colors.grey);
    }

    ref.read(swipeJobDeckProvider.notifier).onSwiped(prevIndex % deck.length);
    return true;
  }

  void _showSwipeSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(swipeJobDeckProvider);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Career Pilot'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(
                  '今日推薦',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '右滑收藏 · 左滑跳過',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Card Swiper ─────────────────────────────────
          Expanded(
            child: deckAsync.when(
              loading: () => const Center(child: JobCardSkeleton()),
              error: (e, _) => Center(child: Text('載入失敗：$e')),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return _EmptyDeck(
                    onRefresh: () => ref.read(swipeJobDeckProvider.notifier).refresh(),
                  );
                }
                return CardSwiper(
                  controller: _swiperController,
                  cardsCount: jobs.length,
                  numberOfCardsDisplayed: 3,
                  backCardOffset: const Offset(0, 16),
                  scale: 0.92,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  onSwipe: _onSwipe,
                  allowedSwipeDirection:
                      const AllowedSwipeDirection.only(left: true, right: true),
                  cardBuilder: (context, index, _, __) {
                    final job = jobs[index % jobs.length];
                    return SwipeJobCard(job: job);
                  },
                );
              },
            ),
          ),

          // ── Action buttons ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 12, 40, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip
                _ActionButton(
                  onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                  icon: Icons.close_rounded,
                  color: Colors.grey,
                  size: 56,
                ),
                // Info (tap center → detail, handled by card tap)
                _ActionButton(
                  onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                  icon: Icons.favorite_rounded,
                  color: Colors.pink,
                  size: 68,
                  filled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.size,
    this.filled = false,
  });
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: filled ? null : Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : color,
          size: size * 0.44,
        ),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  const _EmptyDeck({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.celebration_outlined, size: 72,
              color: colors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('今天的卡片都看完了！',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('前往探索頁查看更多職缺',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: onRefresh,
            child: const Text('重新載入'),
          ),
        ],
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

- [ ] **Step 3: flutter test**

```powershell
flutter test 2>&1 | Select-Object -Last 5
```

Expected：All passed

- [ ] **Step 4: Commit**

```powershell
git add lib/features/home/presentation/screens/home_screen.dart
git commit -m "feat(m5b): Swipe card home screen — right=favorite, left=skip"
```

---

## Task 4: 最終驗收 + CLAUDE.md + merge

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

- [ ] **Step 3: 更新 CLAUDE.md**

在 Milestone Roadmap 更新：
- M5b：`🔲 規劃中` → `✅ 完成`

在架構說明加入 Swipe 首頁相關：
```
HomeScreen → SwipeJobCard（大張卡片） + SwipeJobDeck（Riverpod 卡片池）
右滑 → FavoriteNotifier.toggle()
左滑 → 跳過（無狀態）
```

- [ ] **Step 4: Commit docs**

```powershell
git add CLAUDE.md
git commit -m "docs(m5b): update CLAUDE.md — M5b swipe home complete"
```

- [ ] **Step 5: merge → dev**

```powershell
git checkout dev
git merge --no-ff feature/m5-navigation-ux -m "feat(m5b): Swipe card home screen complete"
git checkout feature/m5-navigation-ux
git log --oneline -6
```

---

## 驗收標準

- [ ] `dart analyze lib/` → No issues found
- [ ] `flutter test` → All passed
- [ ] 首頁顯示 Swipe 卡片（疊加 3 張），可左右滑動
- [ ] 右滑 → 收藏並顯示 SnackBar
- [ ] 左滑 → 跳過並顯示 SnackBar
- [ ] 底部 ✕ / ❤️ 按鈕觸發相同行為
- [ ] 點擊卡片跳到 JobDetailScreen
- [ ] 卡片滑完顯示 Empty state
