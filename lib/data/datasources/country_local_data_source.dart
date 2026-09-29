import 'package:country_trivia/data/datasources/bundled_countries.dart';
import 'package:country_trivia/domain/entities/country.dart';

/// Offline fallback for the country pool.
abstract interface class CountryLocalDataSource {
  List<Country> loadCountries();
}

/// Reads the snapshot that ships inside the app binary.
///
/// Swapping this for `shared_preferences` or `sqflite` backed storage is a
/// one class change, since the repository only sees the interface.
class BundledCountryLocalDataSource implements CountryLocalDataSource {
  const BundledCountryLocalDataSource();

  @override
  List<Country> loadCountries() => bundledCountries();
}
