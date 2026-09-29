import 'package:meta/meta.dart';

import 'package:country_trivia/core/constants/api_constants.dart';
import 'package:country_trivia/core/error/exceptions.dart';
import 'package:country_trivia/core/network/api_client.dart';
import 'package:country_trivia/data/models/country_model.dart';
import 'package:country_trivia/domain/entities/country.dart';

/// Fetches the country pool over HTTP.
///
/// The brief for this app pointed at `https://getpostman.com`, which is
/// Postman's marketing site rather than an API, so
/// [ApiConstants.countriesUrl] defaults to a working public feed. Because every
/// country API spells its fields differently, [CountryModel.fromJson] accepts
/// the common aliases — pointing this data source at a different provider
/// (including a Postman mock) should only mean changing the URL constant.
abstract interface class CountryRemoteDataSource {
  Future<List<Country>> fetchCountries();
}

class HttpCountryRemoteDataSource implements CountryRemoteDataSource {
  const HttpCountryRemoteDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<Country>> fetchCountries() async {
    final json = await _client.getJson(ApiConstants.countriesUrl);
    return parseCountries(json);
  }

  /// Unwraps the envelope shapes used by the common country APIs: a bare
  /// array, `{data: [...]}`, `{countries: [...]}`, or a nested
  /// `{data: {countries: [...]}}`.
  @visibleForTesting
  static List<Country> parseCountries(Map<String, dynamic> json) {
    Object? node = json;

    for (var depth = 0; depth < 3; depth++) {
      if (node is List) break;
      if (node is! Map<String, dynamic>) break;

      final next = node['data'] ?? node['countries'] ?? node['results'];
      if (next == null || identical(next, node)) break;
      node = next;
    }

    if (node is! List) {
      throw const ParseException('No country list found in the response.');
    }

    final countries = <Country>[];
    for (final entry in node) {
      if (entry is! Map<String, dynamic>) continue;
      final model = CountryModel.fromJson(entry);
      if (model != null) countries.add(model.toEntity());
    }

    if (countries.isEmpty) {
      throw const ParseException('The response contained no usable countries.');
    }

    // De-duplicate defensively so a bad feed can never produce two identical
    // options inside the same question.
    final seen = <String>{};
    return countries.where((c) => seen.add(c.isoCode)).toList(growable: false);
  }
}
