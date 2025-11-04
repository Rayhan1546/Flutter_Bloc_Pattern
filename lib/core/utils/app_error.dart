class AppError {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;

  AppError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalError,
  });

  bool get isNetworkError =>
      statusCode == null || statusCode == 0 || statusCode == 408;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'AppError: $message (code: $statusCode)';
}
