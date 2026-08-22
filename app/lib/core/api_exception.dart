enum NetworkErrorKind { noConnection, timeout }

class NetworkException implements Exception {
  final NetworkErrorKind kind;

  const NetworkException(this.kind);
}

class ApiException implements Exception {
  final int statusCode;
  final String error;
  final String message;

  const ApiException({
    required this.statusCode,
    required this.error,
    required this.message,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isInsufficientBalance => error == 'insufficient_balance';
}
