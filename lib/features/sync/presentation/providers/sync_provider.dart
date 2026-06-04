import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../jobs/presentation/providers/job_list_provider.dart';

part 'sync_provider.g.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.jobsUpserted,
    this.errorMessage,
  });

  final SyncStatus status;
  final DateTime? lastSyncTime;
  final int? jobsUpserted;
  final String? errorMessage;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    int? jobsUpserted,
    String? errorMessage,
  }) =>
      SyncState(
        status: status ?? this.status,
        lastSyncTime: lastSyncTime ?? this.lastSyncTime,
        jobsUpserted: jobsUpserted ?? this.jobsUpserted,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

@riverpod
class SyncNotifier extends _$SyncNotifier {
  @override
  SyncState build() => const SyncState();

  Future<void> sync() async {
    if (state.status == SyncStatus.syncing) return;
    state = state.copyWith(status: SyncStatus.syncing);

    try {
      final client = ref.read(apiClientProvider);
      final result = await client.post('/api/v1/sync');
      final count = (result['jobsUpserted'] as num?)?.toInt() ?? 0;
      state = state.copyWith(
        status: SyncStatus.success,
        lastSyncTime: DateTime.now(),
        jobsUpserted: count,
      );
      ref.invalidate(jobListProvider);
    } on ApiException catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}
