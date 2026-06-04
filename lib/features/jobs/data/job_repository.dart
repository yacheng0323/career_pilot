import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../core/network/api_exception.dart';
import '../domain/job.dart';
import 'job_remote_datasource.dart';

class JobRepository {
  JobRepository({JobRemoteDataSource? remoteDataSource})
      : _remote = remoteDataSource;

  static const _assetPath = 'assets/mock/jobs.json';

  final JobRemoteDataSource? _remote;

  Future<List<Job>> fetchAll({String query = ''}) async {
    if (_remote != null) {
      try {
        return await _remote.fetchAll(query: query);
      } on ApiException {
        // API unavailable — fall through to mock
      } catch (_) {
        // Any other error — fall through to mock
      }
    }
    return _loadMock(query: query);
  }

  Future<List<Job>> _loadMock({String query = ''}) async {
    final jsonString = await rootBundle.loadString(_assetPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
    final all = jsonList
        .map((e) => Job.fromJson(e as Map<String, dynamic>))
        .toList();
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
}
