import 'package:country_trivia/domain/entities/country.dart';

/// Data layer representation of a country.
///
/// Country APIs are inconsistent about casing (`Iso2` vs `iso2`) and naming
/// (`name` vs `common` vs `country`), so parsing accepts the aliases used in
/// the wild. The normalised [Country] entity is what the rest of the app sees.
class CountryModel {
  const CountryModel._({required this.name, required this.isoCode});

  final String name;
  final String isoCode;

  /// Field aliases seen across the popular country APIs.
  static const List<String> _nameKeys = [
    'name',
    'common',
    'country',
    'country_name',
    'official',
    'Name',
  ];

  static const List<String> _isoKeys = [
    'iso2',
    'Iso2',
    'cca2',
    'alpha2Code',
    'alpha2',
    'code',
    'ISO2',
  ];

  /// Returns `null` when the entry is missing a usable name or a valid
  /// two letter code, so partially broken feeds degrade instead of crashing.
  static CountryModel? fromJson(Map<String, dynamic> json) {
    final name = _readName(json);
    final iso = _firstString(json, _isoKeys);

    if (name == null || name.isEmpty) return null;
    if (iso == null || iso.length != 2) return null;

    return CountryModel._(name: name, isoCode: iso.toLowerCase());
  }

  Country toEntity() => Country(name: name, isoCode: isoCode);

  /// Reads the country name, including the nested form used by restcountries
  /// style feeds where `name` is `{common: ..., official: ...}`.
  static String? _readName(Map<String, dynamic> json) {
    final nested = json['name'];
    if (nested is Map<String, dynamic>) {
      final common = _firstString(nested, const ['common', 'official']);
      if (common != null) return common;
    }
    return _firstString(json, _nameKeys);
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
