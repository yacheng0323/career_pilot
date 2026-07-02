class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  factory ApiException.network(String detail) =>
      ApiException(statusCode: 0, message: 'Network error: $detail');

  factory ApiException.fromStatus(int statusCode) => ApiException(
        statusCode: statusCode,
        message: 'HTTP $statusCode',
      );

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
