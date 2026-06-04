import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'favorite_provider.dart';

part 'apply_status_provider.g.dart';

enum ApplyStatus {
  none('—'),
  wantToApply('想投'),
  applied('已投'),
  interview('面試'),
  rejected('已拒絕');

  const ApplyStatus(this.label);
  final String label;

  static ApplyStatus fromString(String? value) =>
      ApplyStatus.values.firstWhere((s) => s.name == value,
          orElse: () => ApplyStatus.none);
}

@riverpod
class ApplyStatusNotifier extends _$ApplyStatusNotifier {
  static String _key(String jobId) => 'apply_status_$jobId';

  @override
  Future<ApplyStatus> build(String jobId) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    return ApplyStatus.fromString(prefs.getString(_key(jobId)));
  }

  Future<void> setStatus(ApplyStatus status) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (status == ApplyStatus.none) {
      await prefs.remove(_key(jobId));
    } else {
      await prefs.setString(_key(jobId), status.name);
    }
    state = AsyncData(status);
  }
}
