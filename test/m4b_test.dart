import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/theme/app_theme.dart';
import 'package:career_pilot/core/ai/ai_service.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses Material3', () {
      expect(AppTheme.light.useMaterial3, isTrue);
    });

    test('dark theme exists and uses Material3', () {
      expect(AppTheme.dark.useMaterial3, isTrue);
    });

    test('dark theme brightness is dark', () {
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });

    test('light and dark use same seed color (non-null primaries)', () {
      expect(AppTheme.light.colorScheme.primary, isNotNull);
      expect(AppTheme.dark.colorScheme.primary, isNotNull);
    });
  });

  group('AiService', () {
    test('uses mock when apiKey is empty', () {
      final svc = AiService(apiKey: '');
      expect(svc.useMock, isTrue);
    });

    test('uses real API when apiKey is provided', () {
      final svc = AiService(apiKey: 'sk-ant-test');
      expect(svc.useMock, isFalse);
    });

    test('mock returns 3 non-empty bullets', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Flutter Dev',
        company: 'Acme',
        description: 'Build apps',
        jobSkills: ['Flutter', 'Dart'],
        userSkills: ['Flutter'],
      );
      expect(result.summaryBullets.length, 3);
      expect(result.summaryBullets.every((b) => b.isNotEmpty), isTrue);
    });

    test('match score is 0-100', () async {
      final svc = AiService(apiKey: '', useMock: true);
      final result = await svc.analyze(
        jobTitle: 'Flutter Dev',
        company: 'Acme',
        description: 'Build apps',
        jobSkills: ['Flutter', 'Dart'],
        userSkills: [],
      );
      expect(result.matchScore, inInclusiveRange(0, 100));
    });
  });
}
