import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

import 'package:career_pilot/features/tracker/domain/job_memo.dart';
import 'package:career_pilot/features/tracker/presentation/providers/job_memo_provider.dart';
import 'package:career_pilot/features/tracker/presentation/widgets/memo_card.dart';

ProviderContainer _makeContainer({
  Map<String, Object> prefs = const {},
}) {
  SharedPreferences.setMockInitialValues(prefs);
  return ProviderContainer();
}

void main() {
  group('JobMemoNotifier', () {
    test('starts empty when nothing saved', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final memo = await container.read(jobMemoNotifierProvider('j1').future);
      expect(memo.note, isEmpty);
      expect(memo.interviewAt, isNull);
    });

    test('setNote persists and reloads', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(jobMemoNotifierProvider('j1').future);
      await container
          .read(jobMemoNotifierProvider('j1').notifier)
          .setNote('記得帶作品集');

      final memo = await container.read(jobMemoNotifierProvider('j1').future);
      expect(memo.note, '記得帶作品集');

      // Fresh container simulates app restart — reads same mock store.
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final reloaded =
          await container2.read(jobMemoNotifierProvider('j1').future);
      expect(reloaded.note, '記得帶作品集');
    });

    test('setInterviewDate round-trips through JSON', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final when = DateTime(2026, 7, 10, 14, 30);

      await container.read(jobMemoNotifierProvider('j1').future);
      await container
          .read(jobMemoNotifierProvider('j1').notifier)
          .setInterviewDate(when);

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final reloaded =
          await container2.read(jobMemoNotifierProvider('j1').future);
      expect(reloaded.interviewAt, when);
    });

    test('clearing note and date removes the stored key', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(jobMemoNotifierProvider('j1').notifier);

      await container.read(jobMemoNotifierProvider('j1').future);
      await notifier.setNote('temp');
      await notifier.setInterviewDate(DateTime(2026, 7, 10));
      await notifier.setNote('');
      await notifier.setInterviewDate(null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('job_memo_j1'), isNull);
    });

    test('corrupt JSON falls back to empty memo', () async {
      final container = _makeContainer(
        prefs: {'job_memo_j1': 'not-json{{'},
      );
      addTearDown(container.dispose);

      final memo = await container.read(jobMemoNotifierProvider('j1').future);
      expect(memo.note, isEmpty);
      expect(memo.interviewAt, isNull);
    });

    test('memos are independent per jobId', () async {
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(jobMemoNotifierProvider('a').future);
      await container.read(jobMemoNotifierProvider('b').future);
      await container.read(jobMemoNotifierProvider('a').notifier).setNote('A');

      final b = await container.read(jobMemoNotifierProvider('b').future);
      expect(b.note, isEmpty);
    });
  });

  group('interviewUrgency', () {
    final now = DateTime(2026, 7, 2, 12);

    test('past interview', () {
      expect(interviewUrgency(DateTime(2026, 7, 1), now),
          InterviewUrgency.past);
    });

    test('within 3 days is imminent', () {
      expect(interviewUrgency(DateTime(2026, 7, 4), now),
          InterviewUrgency.imminent);
    });

    test('within 7 days is soon', () {
      expect(interviewUrgency(DateTime(2026, 7, 8), now),
          InterviewUrgency.soon);
    });

    test('beyond 7 days is scheduled', () {
      expect(interviewUrgency(DateTime(2026, 7, 20), now),
          InterviewUrgency.scheduled);
    });
  });

  group('formatInterviewAt', () {
    test('formats month/day hour:minute with zero padding', () {
      expect(formatInterviewAt(DateTime(2026, 7, 10, 9, 5)), '7/10 09:05');
    });
  });

  group('MemoCard widget', () {
    Widget wrap(Widget child) =>
        MaterialApp(home: Scaffold(body: child));

    testWidgets('shows note field and date set button when empty',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(ProviderScope(
        child: wrap(const MemoCard(jobId: 'j1')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('我的備忘錄'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('shows saved note and interview date', (tester) async {
      SharedPreferences.setMockInitialValues({
        'job_memo_j1':
            '{"note":"帶作品集","interviewAt":"2026-07-10T14:30:00.000"}',
      });
      await tester.pumpWidget(ProviderScope(
        child: wrap(const MemoCard(jobId: 'j1')),
      ));
      await tester.pumpAndSettle();

      expect(find.text('帶作品集'), findsOneWidget);
      expect(find.text('7/10 14:30'), findsOneWidget);
    });

    testWidgets('clear button removes interview date', (tester) async {
      SharedPreferences.setMockInitialValues({
        'job_memo_j1':
            '{"note":"","interviewAt":"2026-07-10T14:30:00.000"}',
      });
      await tester.pumpWidget(ProviderScope(
        child: wrap(const MemoCard(jobId: 'j1')),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('清除面試時間'));
      await tester.pumpAndSettle();

      expect(find.text('7/10 14:30'), findsNothing);
      expect(find.text('設定'), findsOneWidget);
    });
  });
}
