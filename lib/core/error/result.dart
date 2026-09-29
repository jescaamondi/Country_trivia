import 'package:country_trivia/core/error/failures.dart';

/// A minimal `Either`-style result type.
///
/// Repositories return this instead of throwing, which makes every failure
/// mode an explicit branch in the presentation layer rather than a `try`
/// block. Implemented locally to avoid pulling in a functional-programming
/// dependency for one sealed class.
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.success(T value) = Success<T>;

  /// Wraps a [failure].
  const factory Result.failure(Failure failure) = FailureResult<T>;

  /// Whether this result holds a value.
  bool get isSuccess => this is Success<T>;

  /// The value, or `null` when this result is a failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>() => null,
  };

  /// The failure, or `null` when this result is a success.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    FailureResult<T>(:final failure) => failure,
  };
}

/// A [Result] holding a [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// A [Result] holding a [failure].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}
