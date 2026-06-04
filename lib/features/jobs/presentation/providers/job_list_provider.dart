import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/job_repository.dart';
import '../../domain/job.dart';

part 'job_list_provider.g.dart';

/// Fetches all jobs from the mock data source.
/// [query] filters by title or company (case-insensitive); pass empty string for no filter.
@riverpod
Future<List<Job>> jobList(JobListRef ref, {String query = ''}) async {
  final all = await JobRepository().fetchAll();
  if (query.trim().isEmpty) return all;
  final q = query.trim().toLowerCase();
  return all
      .where(
        (j) =>
            j.title.toLowerCase().contains(q) ||
            j.company.toLowerCase().contains(q),
      )
      .toList();
}
