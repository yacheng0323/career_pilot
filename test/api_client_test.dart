import 'package:flutter_test/flutter_test.dart';
import 'package:career_pilot/core/network/api_client.dart';
import 'package:career_pilot/core/network/api_exception.dart';

void main() {
  group('ApiClient', () {
    test('default baseUrl is localhost:8000', () {
      final client = ApiClient();
      expect(client.baseUrl, 'http://localhost:8000');
    });

    test('accepts custom baseUrl via constructor', () {
      final client = ApiClient(baseUrl: 'http://10.0.2.2:8000');
      expect(client.baseUrl, 'http://10.0.2.2:8000');
    });
  });

  group('ApiException', () {
    test('toString includes statusCode and message', () {
      final ex = ApiException(statusCode: 404, message: 'Not found');
      expect(ex.toString(), contains('404'));
      expect(ex.toString(), contains('Not found'));
    });

    test('network error has statusCode 0', () {
      final ex = ApiException.network('timeout');
      expect(ex.statusCode, 0);
      expect(ex.message, contains('timeout'));
    });
  });
}
