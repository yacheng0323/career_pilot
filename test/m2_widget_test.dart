import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_pilot/features/jobs/presentation/providers/favorite_provider.dart';
import 'package:career_pilot/features/jobs/presentation/providers/apply_status_provider.dart';

// Stub SharedPreferences with in-memory values so tests are hermetic.
ProviderContainer _makeContainer({
  Map<String, Object> prefs = const {},
}) {
  SharedPreferences.setMockInitialValues(prefs);
  return ProviderContainer();
}

void main() {
  group('FavoriteNotifier', () {
    test('starts empty', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final state = await container.read(favoriteNotifierProvider.future);
      expect(state, isEmpty);
    });

    test('toggle adds a job id', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(favoriteNotifierProvider.future);
      await container.read(favoriteNotifierProvider.notifier).toggle('job-1');

      final state = await container.read(favoriteNotifierProvider.future);
      expect(state, contains('job-1'));
    });

    test('double toggle removes the job id', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(favoriteNotifierProvider.future);
      final notifier = container.read(favoriteNotifierProvider.notifier);
      await notifier.toggle('job-1');
      await notifier.toggle('job-1');

      final state = await container.read(favoriteNotifierProvider.future);
      expect(state, isNot(contains('job-1')));
    });

    test('loads persisted favorites on startup', () async {
      final container = _makeContainer(
        prefs: {'favorite_job_ids': <String>['job-42']},
      );
      addTearDown(container.dispose);

      final state = await container.read(favoriteNotifierProvider.future);
      expect(state, contains('job-42'));
    });
  });

  group('ApplyStatusNotifier', () {
    test('defaults to ApplyStatus.none', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final status =
          await container.read(applyStatusNotifierProvider('job-1').future);
      expect(status, ApplyStatus.none);
    });

    test('setStatus persists the chosen status', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(applyStatusNotifierProvider('job-1').future);
      await container
          .read(applyStatusNotifierProvider('job-1').notifier)
          .setStatus(ApplyStatus.applied);

      final status =
          await container.read(applyStatusNotifierProvider('job-1').future);
      expect(status, ApplyStatus.applied);
    });

    test('setStatus(none) resets to none', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(applyStatusNotifierProvider('job-1').future);
      final notifier =
          container.read(applyStatusNotifierProvider('job-1').notifier);
      await notifier.setStatus(ApplyStatus.interview);
      await notifier.setStatus(ApplyStatus.none);

      final status =
          await container.read(applyStatusNotifierProvider('job-1').future);
      expect(status, ApplyStatus.none);
    });

    test('ApplyStatus labels are correct', () {
      expect(ApplyStatus.wantToApply.label, '想投');
      expect(ApplyStatus.applied.label, '已投');
      expect(ApplyStatus.interview.label, '面試');
      expect(ApplyStatus.rejected.label, '已拒絕');
    });
  });
}
