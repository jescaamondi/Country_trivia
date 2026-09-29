import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_trivia/core/constants/api_constants.dart';
import 'package:country_trivia/core/error/exceptions.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper around [http.Client] that normalises transport errors.
///
/// Every method either returns a decoded JSON body or throws an
/// [ApiException]; nothing else in the app touches `dart:io` directly.
class ApiClient {
  ApiClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? ApiConstants.timeout;

  final http.Client _client;
  final Duration _timeout;

  /// Issues a GET request and returns the decoded JSON body.
  ///
  /// The body is returned as [Object] because country feeds disagree on the
  /// root shape: some return a bare array, others an envelope object. Shape
  /// handling belongs to the data source that knows the provider.
  Future<Object?> getJson(String url) async {
    late final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url), headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } on SocketException {
      throw const ApiException('No network connection available.');
    } on http.ClientException catch (e) {
      throw ApiException('Network request failed: ${e.message}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Request failed with status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw const ParseException('The response body was not valid JSON.');
    }
  }

  void close() => _client.close();
}
