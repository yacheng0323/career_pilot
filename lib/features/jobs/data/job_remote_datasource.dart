import 'dart:math';

import '../../../core/network/api_client.dart';
import '../domain/job.dart';

class JobRemoteDataSource {
  const JobRemoteDataSource({required this.client});

  final ApiClient client;

  /// Fetches jobs from the API and interleaves results from all sources
  /// so the list is not dominated by whichever source was crawled first.
  Future<List<Job>> fetchAll({String query = ''}) async {
    // Fetch a large pool so we have enough from every source
    final params = <String, dynamic>{
      'limit': 300,
      if (query.isNotEmpty) 'q': query,
    };
    final data = await client.get('/api/v1/jobs', params: params);
    final items = (data['items'] as List<dynamic>?) ?? [];
    final jobs = items
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();

    if (query.isNotEmpty) {
      // When searching, preserve relevance order
      return jobs;
    }

    // Group by source then interleave so each source appears evenly
    return _interleave(jobs);
  }

  /// Round-robin interleave: picks one from each source in turn.
  /// e.g. [104_a, yourator_a, remotive_a, 104_b, yourator_b, ...]
  static List<Job> _interleave(List<Job> jobs) {
    final groups = <String, List<Job>>{};
    for (final job in jobs) {
      (groups[job.source] ??= []).add(job);
    }

    // Shuffle within each source group for variety
    final rng = Random();
    for (final list in groups.values) {
      list.shuffle(rng);
    }

    // Round-robin pick
    final result = <Job>[];
    final sources = groups.values.toList();
    int i = 0;
    while (sources.any((s) => s.isNotEmpty)) {
      final source = sources[i % sources.length];
      if (source.isNotEmpty) result.add(source.removeAt(0));
      i++;
    }
    return result;
  }
}
