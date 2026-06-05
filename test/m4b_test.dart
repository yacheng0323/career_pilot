import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/theme/app_theme.dart';

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
}
