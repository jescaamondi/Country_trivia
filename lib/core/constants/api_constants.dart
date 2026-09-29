/// Central configuration for every remote endpoint the app depends on.
///
/// Keeping URLs in one place makes it trivial to point the app at a different
/// country feed (a self-hosted mirror, a Postman mock, a staging backend, ...)
/// without touching the data or presentation layers.
class ApiConstants {
  const ApiConstants._();

  /// Primary source for the country pool.
  ///
  /// The prompt this project was built from referenced `https://getpostman.com`,
  /// which is Postman's marketing site rather than an API, so a working,
  /// key-free public feed is used as the default. The response parser
  /// ([CountryModel.fromJson]) is deliberately lenient about field names, so
  /// swapping this constant for a different provider is usually all that is
  /// required.
  static const String countriesUrl =
      'https://countriesnow.space/api/v0.1/countries/iso';

  /// How long to wait for the country feed before giving up.
  static const Duration timeout = Duration(seconds: 20);
}

/// Configuration for the flag image CDN.
class FlagConstants {
  const FlagConstants._();

  static const String _host = 'https://flagcdn.com';

  /// Width bucket requested from the CDN. `w320` keeps payloads tiny while
  /// still looking sharp on high density phones.
  static const String _width = 'w320';

  /// Builds the flag image URL for a lowercase ISO 3166-1 alpha-2 code.
  ///
  /// Note: the bare `https://flagcdn.com/{iso}.png` form returns a 404 — the
  /// size segment is required.
  static String imageUrl(String isoCode) {
    final normalized = isoCode.trim().toLowerCase();
    return '$_host/$_width/$normalized.png';
  }
}
