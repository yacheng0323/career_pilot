import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/jobs/domain/job.dart';
import '../../../../features/jobs/presentation/providers/job_list_provider.dart';

part 'swipe_job_provider.g.dart';

@riverpod
class SwipeJobDeck extends _$SwipeJobDeck {
  static const _deckSize = 15;

  @override
  AsyncValue<List<Job>> build() {
    final jobsAsync = ref.watch(jobListProvider());
    return jobsAsync.whenData((jobs) => jobs.take(_deckSize).toList());
  }

  void onSwiped(int index) {
    final jobs = state.valueOrNull;
    if (jobs == null || jobs.isEmpty) return;

    final sourceJobs = ref.read(jobListProvider()).valueOrNull ?? [];
    final remaining = List<Job>.from(jobs)..removeAt(index);

    final inDeck = remaining.map((j) => j.id).toSet();
    final next = sourceJobs.firstWhere(
      (j) => !inDeck.contains(j.id),
      orElse: () => sourceJobs.first,
    );

    remaining.add(next);
    state = AsyncData(remaining);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}
