import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/job_remote_datasource.dart';
import '../../data/job_repository.dart';
import '../../domain/job.dart';

part 'job_list_provider.g.dart';

@Riverpod(keepAlive: true)
ApiClient apiClient(ApiClientRef ref) => ApiClient();

@riverpod
Future<List<Job>> jobList(JobListRef ref, {String query = ''}) async {
  final client = ref.watch(apiClientProvider);
  final repo = JobRepository(
    remoteDataSource: JobRemoteDataSource(client: client),
  );
  return repo.fetchAll(query: query);
}
