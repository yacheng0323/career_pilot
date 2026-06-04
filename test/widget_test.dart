import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:career_pilot/features/jobs/domain/job.dart';
import 'package:career_pilot/features/jobs/presentation/widgets/job_card.dart';
import 'package:career_pilot/features/jobs/presentation/widgets/skill_chip.dart';
import 'package:career_pilot/core/theme/app_theme.dart';

// JobCard is a ConsumerWidget — needs ProviderScope + SharedPreferences stub.
Widget _wrap(Widget child) {
  SharedPreferences.setMockInitialValues({});
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.light, home: Scaffold(body: child)),
  );
}

final _mockJob = Job(
  id: 'test-1',
  title: 'Flutter Developer',
  company: 'Acme Corp',
  location: '台北',
  isRemote: true,
  salaryRange: '800K–1.2M',
  skills: ['Flutter', 'Dart', 'Riverpod'],
  description: 'Build awesome apps.',
  source: 'LinkedIn',
);

void main() {
  group('SkillChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrap(const SkillChip(label: 'Flutter')));
      expect(find.text('Flutter'), findsOneWidget);
    });
  });

  group('JobCard', () {
    testWidgets('shows title, company, location and salary', (tester) async {
      await tester.pumpWidget(_wrap(JobCard(job: _mockJob)));
      expect(find.text('Flutter Developer'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('台北'), findsOneWidget);
      expect(find.text('800K–1.2M'), findsOneWidget);
    });

    testWidgets('shows remote badge when isRemote is true', (tester) async {
      await tester.pumpWidget(_wrap(JobCard(job: _mockJob)));
      expect(find.text('遠端'), findsOneWidget);
    });

    testWidgets('does not show remote badge when isRemote is false', (tester) async {
      final offsite = _mockJob.copyWith(isRemote: false);
      await tester.pumpWidget(_wrap(JobCard(job: offsite)));
      expect(find.text('遠端'), findsNothing);
    });

    testWidgets('shows up to 4 skill chips', (tester) async {
      final manySkills = _mockJob.copyWith(
        skills: ['A', 'B', 'C', 'D', 'E', 'F'],
      );
      await tester.pumpWidget(_wrap(JobCard(job: manySkills)));
      // Only 4 SkillChip widgets should be rendered
      expect(find.byType(SkillChip), findsNWidgets(4));
    });

    testWidgets('shows source badge', (tester) async {
      await tester.pumpWidget(_wrap(JobCard(job: _mockJob)));
      expect(find.text('LinkedIn'), findsOneWidget);
    });
  });
}
