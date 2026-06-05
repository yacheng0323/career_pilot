import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/jobs/domain/job.dart';
import '../../../../features/jobs/presentation/providers/favorite_provider.dart';
import '../../../../features/jobs/presentation/providers/job_list_provider.dart';

part 'swipe_job_provider.g.dart';

@riverpod
class SwipeJobDeck extends _$SwipeJobDeck {
  static const _deckSize = 15;

  @override
  AsyncValue<List<Job>> build() {
    final jobsAsync = ref.watch(jobListProvider());
    // Exclude already-favorited jobs from the deck
    final favIds = ref.watch(favoriteNotifierProvider).valueOrNull ?? {};
    return jobsAsync.whenData((jobs) => jobs
        .where((j) => !favIds.contains(j.id))
        .take(_deckSize)
        .toList());
  }

  void onSwiped(int index) {
    final jobs = state.valueOrNull;
    if (jobs == null || jobs.isEmpty) return;

    final favIds = ref.read(favoriteNotifierProvider).valueOrNull ?? {};
    final sourceJobs = ref.read(jobListProvider()).valueOrNull ?? [];
    final remaining = List<Job>.from(jobs)..removeAt(index);

    final inDeck = remaining.map((j) => j.id).toSet();
    // Next card must not be in deck AND not already favorited
    final next = sourceJobs.firstWhere(
      (j) => !inDeck.contains(j.id) && !favIds.contains(j.id),
      orElse: () => sourceJobs.firstWhere(
        (j) => !inDeck.contains(j.id),
        orElse: () => sourceJobs.first,
      ),
    );

    remaining.add(next);
    state = AsyncData(remaining);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
