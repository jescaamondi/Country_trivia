/// Thrown by data sources when a request cannot be completed.
///
/// These are implementation details: the repository converts them into
/// [Failure]s so nothing above the data layer has to catch them.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($message, statusCode: $statusCode)';
}

/// Thrown when a successful response body cannot be mapped to a model.
class ParseException implements Exception {
  const ParseException(this.message);

  final String message;

  @override
  String toString() => 'ParseException($message)';
}
