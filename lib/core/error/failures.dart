import 'package:equatable/equatable.dart';

/// A domain level description of something that went wrong.
///
/// Data layer exceptions (Dart specific, transport oriented) are translated
/// into failures by the repository, so the presentation layer never has to
/// know about `SocketException`, `http` status codes, and friends.
sealed class Failure extends Equatable {
  const Failure(this.message);

  /// A message that is safe to render directly in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The device could not reach the server at all.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Check your network and try again.',
  ]);
}

/// The server was reached but responded with an error status.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'The country service is unavailable right now.',
    this.statusCode,
  ]);

  final int? statusCode;

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// The response arrived but did not contain anything usable.
class ParseFailure extends Failure {
  const ParseFailure([
    super.message = 'The country data came back in an unexpected format.',
  ]);
}

/// No cached copy was available to fall back on.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'No saved country data is available on this device.',
  ]);
}
