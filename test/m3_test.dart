import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:career_pilot/core/ai/ai_service.dart';
import 'package:career_pilot/features/jobs/domain/job.dart';
import 'package:career_pilot/features/profile/presentation/providers/user_profile_provider.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────

ProviderContainer _makeContainer({Map<String, Object> prefs = const {}}) {
  SharedPreferences.setMockInitialValues(prefs);
  return ProviderContainer();
}

Job _job({
  String id = 'j1',
  String title = 'Flutter Dev',
  String location = '台北市',
  bool isRemote = false,
  List<String> skills = const ['Flutter', 'Dart'],
}) =>
    Job(
      id: id,
      title: title,
      company: 'Acme',
      location: location,
      isRemote: isRemote,
      salaryRange: '80K',
      skills: skills,
      description: 'desc',
      source: 'Test',
    );

// ─── Filter logic tests (pure Dart, no widgets) ────────────────────────────

List<Job> _applyFilters(
  List<Job> jobs, {
  bool remoteOnly = false,
  String? location,
  Set<String> skills = const {},
  Set<String> favIds = const {},
  bool favOnly = false,
}) {
  var result = jobs;
  if (remoteOnly) result = result.where((j) => j.isRemote).toList();
  if (favOnly) result = result.where((j) => favIds.contains(j.id)).toList();
  if (location != null) result = result.where((j) => j.location == location).toList();
  if (skills.isNotEmpty) {
    result = result
        .where((j) => skills.any(
            (s) => j.skills.any((js) => js.toLowerCase() == s.toLowerCase())))
        .toList();
  }
  return result;
}

void main() {
  // ── Filter logic ──────────────────────────────────────────────────────────
  group('Filter logic', () {
    final jobs = [
      _job(id: 'j1', location: '台北市', isRemote: false, skills: ['Flutter', 'Dart']),
      _job(id: 'j2', location: '台中市', isRemote: true, skills: ['React', 'TypeScript']),
      _job(id: 'j3', location: '台北市', isRemote: true, skills: ['Flutter', 'Firebase']),
    ];

    test('remoteOnly filters non-remote jobs', () {
      final result = _applyFilters(jobs, remoteOnly: true);
      expect(result.map((j) => j.id), containsAll(['j2', 'j3']));
      expect(result.map((j) => j.id), isNot(contains('j1')));
    });

    test('location filter works', () {
      final result = _applyFilters(jobs, location: '台中市');
      expect(result.length, 1);
      expect(result.first.id, 'j2');
    });

    test('skill filter (OR) matches any selected skill', () {
      final result = _applyFilters(jobs, skills: {'React', 'Firebase'});
      expect(result.map((j) => j.id), containsAll(['j2', 'j3']));
      expect(result.map((j) => j.id), isNot(contains('j1')));
    });

    test('skill filter is case-insensitive', () {
      final result = _applyFilters(jobs, skills: {'flutter'});
      expect(result.map((j) => j.id), containsAll(['j1', 'j3']));
    });

    test('favOnly shows only favorited jobs', () {
      final result = _applyFilters(jobs, favOnly: true, favIds: {'j1', 'j3'});
      expect(result.map((j) => j.id), containsAll(['j1', 'j3']));
      expect(result.map((j) => j.id), isNot(contains('j2')));
    });

    test('combined filters (remote + location)', () {
      final result = _applyFilters(jobs, remoteOnly: true, location: '台北市');
      expect(result.length, 1);
      expect(result.first.id, 'j3');
    });

    test('no filter returns all jobs', () {
      expect(_applyFilters(jobs).length, jobs.length);
    });
  });

  // ── AiService mock mode ────────────────────────────────────────────────────
  group('AiService (mock mode)', () {
    test('returns 3 summary bullets', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Flutter Dev',
        company: 'Acme',
        description: 'Build apps',
        jobSkills: ['Flutter', 'Dart', 'Riverpod'],
        userSkills: ['Flutter', 'Dart'],
      );
      expect(result.summaryBullets.length, 3);
      expect(result.summaryBullets.every((b) => b.isNotEmpty), isTrue);
    });

    test('match score is within 0–100', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Go Engineer',
        company: 'CloudBase',
        description: 'Microservices',
        jobSkills: ['Go', 'Docker', 'Kubernetes'],
        userSkills: ['Go'],
      );
      expect(result.matchScore, inInclusiveRange(0, 100));
    });

    test('no overlap → score < 50', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'iOS Dev',
        company: 'TechCorp',
        description: 'Build iOS apps',
        jobSkills: ['Swift', 'SwiftUI'],
        userSkills: ['Flutter', 'Dart'],
      );
      expect(result.matchScore, lessThan(50));
    });

    test('full overlap → high score', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Flutter Dev',
        company: 'Acme',
        description: 'Flutter app',
        jobSkills: ['Flutter', 'Dart'],
        userSkills: ['Flutter', 'Dart', 'Riverpod'],
      );
      expect(result.matchScore, greaterThanOrEqualTo(80));
    });

    test('empty userSkills → score 50 (neutral)', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Flutter Dev',
        company: 'Acme',
        description: 'Flutter app',
        jobSkills: ['Flutter', 'Dart'],
        userSkills: [],
      );
      expect(result.matchScore, 50);
    });
  });

  // ── UserProfileNotifier ────────────────────────────────────────────────────
  group('UserProfileNotifier', () {
    test('starts with empty skills', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final profile = await c.read(userProfileNotifierProvider.future);
      expect(profile.skills, isEmpty);
    });

    test('addSkill persists skill', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      await c.read(userProfileNotifierProvider.notifier).addSkill('Flutter');
      final profile = await c.read(userProfileNotifierProvider.future);
      expect(profile.skills, contains('Flutter'));
    });

    test('addSkill is idempotent (no duplicate)', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(userProfileNotifierProvider.notifier);
      await notifier.addSkill('Dart');
      await notifier.addSkill('Dart');
      final profile = await c.read(userProfileNotifierProvider.future);
      expect(profile.skills.where((s) => s == 'Dart').length, 1);
    });

    test('removeSkill removes the skill', () async {
      final c = _makeContainer();
      addTearDown(c.dispose);
      final notifier = c.read(userProfileNotifierProvider.notifier);
      await notifier.addSkill('Go');
      await notifier.removeSkill('Go');
      final profile = await c.read(userProfileNotifierProvider.future);
      expect(profile.skills, isNot(contains('Go')));
    });
  });
}
