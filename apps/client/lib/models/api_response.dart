/// Simple API response wrapper without Freezed - regular Dart class
abstract class ApiResponse<T> {
  const ApiResponse();
}

class ApiSuccess<T> extends ApiResponse<T> {
  final T data;
  final String? message;

  const ApiSuccess({
    required this.data,
    this.message,
  });

  @override
  String toString() => 'ApiSuccess(data: $data, message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiSuccess<T> && other.data == data && other.message == message;
  }

  @override
  int get hashCode => Object.hash(data, message);
}

class ApiError<T> extends ApiResponse<T> {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  const ApiError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiError(message: $message, statusCode: $statusCode, errorCode: $errorCode)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiError<T> &&
        other.message == message &&
        other.statusCode == statusCode &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode => Object.hash(message, statusCode, errorCode);
}

class ApiLoading<T> extends ApiResponse<T> {
  const ApiLoading();

  @override
  String toString() => 'ApiLoading()';

  @override
  bool operator ==(Object other) => other is ApiLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Extension for ApiResponse convenience methods
extension ApiResponseExtension<T> on ApiResponse<T> {
  /// Check if response is successful
  bool get isSuccess => this is ApiSuccess<T>;
  
  /// Check if response is an error
  bool get isError => this is ApiError<T>;
  
  /// Check if response is loading
  bool get isLoading => this is ApiLoading<T>;
  
  /// Get data or null
  T? get dataOrNull => isSuccess ? (this as ApiSuccess<T>).data : null;
  
  /// Get error message or null
  String? get errorMessage => isError ? (this as ApiError<T>).message : null;
  
  /// Get status code or null
  int? get statusCode => isError ? (this as ApiError<T>).statusCode : null;

  /// Pattern matching helper - synchronous version
  R when<R>({
    required R Function(T data, String? message) success,
    required R Function(String message, int? statusCode, String? errorCode, dynamic details) error,
    required R Function() loading,
  }) {
    if (this is ApiSuccess<T>) {
      final s = this as ApiSuccess<T>;
      return success(s.data, s.message);
    } else if (this is ApiError<T>) {
      final e = this as ApiError<T>;
      return error(e.message, e.statusCode, e.errorCode, e.details);
    } else {
      return loading();
    }
  }
}

/// Helper to create common API responses
class ApiResponseHelper {
  static ApiResponse<T> success<T>(T data, {String? message}) {
    return ApiSuccess<T>(data: data, message: message);
  }
  
  static ApiResponse<T> error<T>(String message, {int? statusCode, String? errorCode}) {
    return ApiError<T>(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }
  
  static ApiResponse<T> loading<T>() {
    return ApiLoading<T>();
  }
  
  static ApiResponse<T> networkError<T>() {
    return ApiError<T>(
      message: 'Network connection failed. Please check your internet connection.',
      statusCode: -1,
      errorCode: 'NETWORK_ERROR',
    );
  }
  
  static ApiResponse<T> timeoutError<T>() {
    return ApiError<T>(
      message: 'Request timeout. Please try again.',
      statusCode: -2,
      errorCode: 'TIMEOUT_ERROR',
    );
  }
  
  static ApiResponse<T> serverError<T>() {
    return ApiError<T>(
      message: 'Server error occurred. Please try again later.',
      statusCode: 500,
      errorCode: 'SERVER_ERROR',
    );
  }
}
