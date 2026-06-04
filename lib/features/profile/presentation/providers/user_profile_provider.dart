import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/jobs/presentation/providers/favorite_provider.dart';
import '../../domain/user_profile.dart';

part 'user_profile_provider.g.dart';

@Riverpod(keepAlive: true)
class UserProfileNotifier extends _$UserProfileNotifier {
  static const _key = 'user_profile';

  @override
  Future<UserProfile> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_key);
    if (raw == null) return const UserProfile();
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> addSkill(String skill) async {
    final profile = await future;
    if (profile.skills.contains(skill)) return;
    await _save(profile.copyWith(skills: [...profile.skills, skill]));
  }

  Future<void> removeSkill(String skill) async {
    final profile = await future;
    await _save(
        profile.copyWith(skills: profile.skills.where((s) => s != skill).toList()));
  }

  Future<void> setName(String name) async {
    final profile = await future;
    await _save(profile.copyWith(name: name));
  }

  Future<void> _save(UserProfile updated) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_key, jsonEncode(updated.toJson()));
    state = AsyncData(updated);
  }
}
