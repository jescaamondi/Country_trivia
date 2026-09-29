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

  /// Issues a GET request and returns the decoded JSON object.
  Future<Map<String, dynamic>> getJson(String url) async {
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
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ParseException('Expected a JSON object at the root.');
      }
      return decoded;
    } on FormatException {
      throw const ParseException('The response body was not valid JSON.');
    }
  }

  void close() => _client.close();
}
