import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'favorite_provider.g.dart';

// Low-level SharedPreferences provider — resolved once at startup.
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();

@riverpod
class FavoriteNotifier extends _$FavoriteNotifier {
  static const _key = 'favorite_job_ids';

  @override
  Future<Set<String>> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> toggle(String jobId) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.valueOrNull ?? {};
    final updated = current.contains(jobId)
        ? (current.toSet()..remove(jobId))
        : (current.toSet()..add(jobId));
    await prefs.setStringList(_key, updated.toList());
    state = AsyncData(updated);
  }

  bool isFavorite(String jobId) => state.valueOrNull?.contains(jobId) ?? false;
}
