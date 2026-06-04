import 'package:dio/dio.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000',
            ) {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  final String baseUrl;
  late final Dio _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromStatus(e.response!.statusCode ?? 0);
      }
      throw ApiException.network(e.message ?? 'unknown');
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromStatus(e.response!.statusCode ?? 0);
      }
      throw ApiException.network(e.message ?? 'unknown');
    }
  }
}
