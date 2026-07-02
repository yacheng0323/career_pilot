import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../jobs/presentation/providers/favorite_provider.dart';
import '../../domain/job_memo.dart';

part 'job_memo_provider.g.dart';

@riverpod
class JobMemoNotifier extends _$JobMemoNotifier {
  static String _key(String jobId) => 'job_memo_$jobId';

  @override
  Future<JobMemo> build(String jobId) async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final raw = prefs.getString(_key(jobId));
    if (raw == null) return const JobMemo();
    try {
      return JobMemo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const JobMemo();
    }
  }

  Future<void> setNote(String note) async {
    final current = state.valueOrNull ?? const JobMemo();
    await _save(current.copyWith(note: note));
  }

  Future<void> setInterviewDate(DateTime? interviewAt) async {
    final current = state.valueOrNull ?? const JobMemo();
    await _save(current.copyWith(interviewAt: () => interviewAt));
  }

  Future<void> _save(JobMemo memo) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (memo.isEmpty) {
      await prefs.remove(_key(jobId));
    } else {
      await prefs.setString(_key(jobId), jsonEncode(memo.toJson()));
    }
    state = AsyncData(memo);
  }
}
