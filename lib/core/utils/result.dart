import 'package:junie_ai_test/core/utils/app_error.dart';

/// A Result type for handling success and error cases
/// This replaces the Either type from dartz package
sealed class Result<T> {
  const Result();
}

/// Success result containing the data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);
}

/// Error result containing the error information
class Error<T> extends Result<T> {
  final AppError error;

  const Error(this.error);
}

/// Extension methods for Result type
extension ResultExtension<T> on Result<T> {
  /// Returns true if this is a Success result
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is an Error result
  bool get isError => this is Error<T>;

  /// Get the data if Success, otherwise null
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  /// Get the error if Error, otherwise null
  AppError? get errorOrNull =>
      this is Error<T> ? (this as Error<T>).error : null;

  /// Execute different functions based on result type
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) onError,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Error<T>(:final error) => onError(error),
    };
  }

  /// Execute different functions based on result type (nullable return)
  R? whenOrNull<R>({
    R Function(T data)? success,
    R Function(AppError error)? onError,
  }) {
    return switch (this) {
      Success<T>(:final data) => success?.call(data),
      Error<T>(:final error) => onError?.call(error),
    };
  }
}
