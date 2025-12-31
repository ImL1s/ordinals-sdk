/// Result type for handling success/failure without exceptions
class Result<T> {
  final T? _value;
  final String? _error;
  final String? code;

  Result._(this._value, this._error, {this.code});

  /// Create a successful result with value
  factory Result.success(T value) => Result._(value, null);

  /// Create a failed result with error message
  factory Result.failure(String error, {String? code}) =>
      Result._(null, error, code: code);

  /// Whether this result is successful
  bool get isSuccess => _error == null;

  /// Whether this result is a failure
  bool get isFailure => _error != null;

  /// Get the value or null if failed
  T? get valueOrNull => _value;

  /// Get the error or null if successful
  String? get errorOrNull => _error;

  /// Get the value or throw if failed
  T get value {
    if (isFailure) {
      throw Exception(_error);
    }
    return _value as T;
  }

  /// Transform the value if successful
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return Result.success(transform(_value as T));
    }
    return Result.failure(_error!, code: code);
  }

  /// Transform the result with an async function
  Future<Result<R>> mapAsync<R>(Future<R> Function(T) transform) async {
    if (isSuccess) {
      return Result.success(await transform(_value as T));
    }
    return Result.failure(_error!, code: code);
  }

  /// Handle both success and failure cases
  R when<R>({
    required R Function(T value) success,
    required R Function(String error) failure,
  }) {
    if (isSuccess) {
      return success(_value as T);
    }
    return failure(_error!);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($_value)';
    }
    return 'Result.failure($_error)';
  }
}
