final class ApiException implements Exception {
  final int status;
  final String error;
  final String message;

  const ApiException({
    required this.status,
    required this.message,
    required this.error,
  });

  @override
  String toString() {
    return 'ApiException($status, $error): $message';
  }
}
