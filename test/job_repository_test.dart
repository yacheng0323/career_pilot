import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/network/api_client.dart';
import 'package:career_pilot/core/network/api_exception.dart';
import 'package:career_pilot/features/jobs/data/job_remote_datasource.dart';
import 'package:career_pilot/features/jobs/data/job_repository.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.fakeResponse}) : super(baseUrl: 'http://test');
  final dynamic fakeResponse;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async =>
      fakeResponse;
}

class _ErrorApiClient extends ApiClient {
  _ErrorApiClient() : super(baseUrl: 'http://test');

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    throw ApiException.network('connection refused');
  }
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

  group('JobRepository fallback', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Provide mock asset so rootBundle.loadString works in tests
      const mockJson = '''[
        {
          "id": "test_001",
          "title": "Test Job",
          "company": "Test Co",
          "location": "Remote",
          "isRemote": true,
          "salaryRange": "100K",
          "skills": ["Dart"],
          "description": "A test job",
          "source": "test",
          "url": "https://test.example.com",
          "crawledAt": "2026-06-04T00:00:00.000"
        }
      ]''';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
        // The message is the asset key as UTF-8
        final key = utf8.decode(message!.buffer.asUint8List());
        if (key == 'assets/mock/jobs.json') {
          final encoded = utf8.encode(mockJson);
          return ByteData.sublistView(Uint8List.fromList(encoded));
        }
        return null;
      });
    });

    test('returns mock JSON when API throws ApiException', () async {
      // _ErrorApiClient always throws
      final repo = JobRepository(
        remoteDataSource: JobRemoteDataSource(client: _ErrorApiClient()),
      );
      final jobs = await repo.fetchAll();
      expect(jobs, isNotEmpty);
      expect(jobs.first.id, isNotEmpty);
    });
  });
}
