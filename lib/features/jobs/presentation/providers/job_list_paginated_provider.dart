import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/job.dart';
import 'job_list_provider.dart';

part 'job_list_paginated_provider.g.dart';

@riverpod
class JobListPaginated extends _$JobListPaginated {
  static const _pageSize = 20;

  int _page = 1;
  bool _hasMore = true;
  List<Job> _allJobs = [];
  String _query = '';

  @override
  AsyncValue<List<Job>> build() => const AsyncData([]);

  bool get hasMore => _hasMore;

  Future<void> init({String query = ''}) async {
    _query = query;
    _page = 1;
    _hasMore = true;
    _allJobs = [];
    await _fetch();
  }

  Future<void> fetchMore() async {
    if (!_hasMore || state.isLoading) return;
    _page++;
    await _fetch(append: true);
  }

  Future<void> refresh({String query = ''}) async {
    await init(query: query.isNotEmpty ? query : _query);
  }

  Future<void> _fetch({bool append = false}) async {
    if (!append) state = const AsyncLoading();

    try {
      final client = ref.read(apiClientProvider);
      final params = <String, dynamic>{
        'limit': _pageSize,
        'page': _page,
        if (_query.isNotEmpty) 'q': _query,
      };
      final data = await client.get('/api/v1/jobs', params: params);
      final items = (data['items'] as List<dynamic>?) ?? [];
      final total = (data['total'] as num?)?.toInt() ?? 0;
      final newJobs = items
          .map((e) => Job.fromJson(e as Map<String, dynamic>))
          .toList();

      if (append) {
        _allJobs = [..._allJobs, ...newJobs];
      } else {
        _allJobs = newJobs;
      }

      _hasMore = _allJobs.length < total;
      state = AsyncData(List.unmodifiable(_allJobs));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
