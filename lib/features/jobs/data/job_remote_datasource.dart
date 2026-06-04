import '../../../core/network/api_client.dart';
import '../domain/job.dart';

class JobRemoteDataSource {
  const JobRemoteDataSource({required this.client});

  final ApiClient client;

  Future<List<Job>> fetchAll({String query = ''}) async {
    final params = <String, dynamic>{
      'limit': 100,
      if (query.isNotEmpty) 'q': query,
    };
    final data = await client.get('/api/v1/jobs', params: params);
    final items = (data['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
