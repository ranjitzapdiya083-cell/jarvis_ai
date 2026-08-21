/// A strict success/failure wrapper. Every device-action service returns
/// this instead of a bare bool, so callers can never accidentally treat
/// a failure as success (spec: "Never fake success").
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;
  factory Result.failure(String message, {String? code}) = Failure<T>;

  bool get isSuccess => this is Success<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, String? code) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    if (self is Failure<T>) return failure(self.message, self.code);
    throw StateError('Unreachable');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final String? code;
  const Failure(this.message, {this.code});
}
