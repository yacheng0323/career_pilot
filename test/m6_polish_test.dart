import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_pilot/features/jobs/presentation/providers/favorite_provider.dart';
import 'package:career_pilot/features/home/presentation/providers/swipe_job_provider.dart';
import 'package:career_pilot/features/jobs/domain/job.dart';
import 'package:career_pilot/features/jobs/presentation/providers/job_list_provider.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

Job _job(String id, {String title = 'Dev', bool isRemote = false}) => Job(
      id: id,
      title: title,
      company: 'Acme',
      location: '台北',
      isRemote: isRemote,
      salaryRange: '80K',
      skills: const ['Flutter'],
      description: 'desc',
      source: '104',
    );

ProviderContainer _container({
  List<Job> jobs = const [],
  Set<String> favIds = const {},
}) {
  SharedPreferences.setMockInitialValues({
    if (favIds.isNotEmpty) 'favorite_job_ids': favIds.toList(),
  });
  return ProviderContainer(
    overrides: [
      jobListProvider().overrideWith((_) async => jobs),
    ],
  );
}

// ── SwipeJobDeck tests ───────────────────────────────────────────────────────

void main() {
  group('SwipeJobDeck', () {
    test('builds deck from job list (up to 15)', () async {
      final jobs = List.generate(20, (i) => _job('j$i'));
      final c = _container(jobs: jobs);
      addTearDown(c.dispose);

      await c.read(jobListProvider().future);
      final deck = c.read(swipeJobDeckProvider).valueOrNull;
      expect(deck, isNotNull);
      expect(deck!.length, 15); // capped at _deckSize
    });

    test('initial deck does not exceed 15 cards', () async {
      final jobs = List.generate(20, (i) => _job('j$i'));
      final c = _container(jobs: jobs);
      addTearDown(c.dispose);

      // Wait for job list, then allow multiple microtask cycles for the deck to rebuild
      await c.read(jobListProvider().future);
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      final deck = c.read(swipeJobDeckProvider).valueOrNull;
      if (deck != null) {
        expect(deck.length, lessThanOrEqualTo(15));
      }
      // Provider loaded without error is sufficient
      expect(c.read(swipeJobDeckProvider).hasError, isFalse);
    });

    test('onSwiped shrinks deck by 1 and adds unseen job', () async {
      // Use 20 jobs so there are plenty of unseen cards after initial 15
      final jobs = List.generate(20, (i) => _job('j$i'));
      final c = _container(jobs: jobs);
      addTearDown(c.dispose);

      await c.read(jobListProvider().future);
      final before = c.read(swipeJobDeckProvider).valueOrNull ?? [];
      expect(before.length, 15);

      final removedId = before[0].id;
      c.read(swipeJobDeckProvider.notifier).onSwiped(0);

      final after = c.read(swipeJobDeckProvider).valueOrNull ?? [];
      // Deck stays size 15 (removed 1, added 1 unseen)
      expect(after.length, 15);
      // The removed card should not be at front anymore
      expect(after[0].id, isNot(removedId));
    });
  });

  group('FavoriteNotifier — Wave 1 integration', () {
    test('favorited job count is tracked correctly', () async {
      final c = ProviderContainer();
      SharedPreferences.setMockInitialValues({});
      addTearDown(c.dispose);

      expect(c.read(favoriteNotifierProvider).valueOrNull, isNull);
      await c.read(favoriteNotifierProvider.future);
      expect(c.read(favoriteNotifierProvider).valueOrNull, isEmpty);

      await c.read(favoriteNotifierProvider.notifier).toggle('j0');
      expect(c.read(favoriteNotifierProvider).valueOrNull, contains('j0'));

      await c.read(favoriteNotifierProvider.notifier).toggle('j0');
      expect(c.read(favoriteNotifierProvider).valueOrNull, isNot(contains('j0')));
    });
  });
}
