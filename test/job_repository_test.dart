import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/network/api_client.dart';
import 'package:career_pilot/features/jobs/data/job_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.fakeResponse}) : super(baseUrl: 'http://test');
  final dynamic fakeResponse;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async =>
      fakeResponse;
}

void main() {
  group('JobRemoteDataSource', () {
    test('fetchAll returns list of Jobs on success', () async {
      final fakeData = {
        'items': [
          {
            'id': '104_001',
            'title': 'Flutter Dev',
            'company': 'Acme',
            'location': '台北市',
            'isRemote': false,
            'salaryRange': '80K',
            'skills': ['Flutter', 'Dart'],
            'description': 'desc',
            'source': '104',
            'url': 'https://example.com',
            'crawledAt': '2026-06-04T00:00:00.000',
          }
        ],
        'total': 1,
      };
      final ds = JobRemoteDataSource(
          client: _FakeApiClient(fakeResponse: fakeData));
      final jobs = await ds.fetchAll();
      expect(jobs.length, 1);
      expect(jobs.first.id, '104_001');
      expect(jobs.first.url, 'https://example.com');
    });

    test('fetchAll returns empty list on empty items', () async {
      final ds = JobRemoteDataSource(
        client: _FakeApiClient(
            fakeResponse: {'items': [], 'total': 0}),
      );
      final jobs = await ds.fetchAll();
      expect(jobs, isEmpty);
    });
  });
}
