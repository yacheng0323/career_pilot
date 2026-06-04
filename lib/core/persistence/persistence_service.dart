import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  PersistenceService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<PersistenceService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PersistenceService._(prefs);
  }

  // --- favorites ---

  static const _favKey = 'favorite_job_ids';

  Set<String> getFavoriteIds() =>
      (_prefs.getStringList(_favKey) ?? []).toSet();

  Future<void> saveFavoriteIds(Set<String> ids) =>
      _prefs.setStringList(_favKey, ids.toList());

  // --- apply status ---

  static const _applyPrefix = 'apply_status_';

  String? getApplyStatus(String jobId) =>
      _prefs.getString('$_applyPrefix$jobId');

  Future<void> saveApplyStatus(String jobId, String status) =>
      _prefs.setString('$_applyPrefix$jobId', status);

  Future<void> removeApplyStatus(String jobId) =>
      _prefs.remove('$_applyPrefix$jobId');
}
