import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/country.dart';

/// Contract for loading the pool of countries a game is played from.
///
/// Declared in the domain layer and implemented in the data layer so the
/// business rules never depend on HTTP or caching details.
abstract interface class CountryRepository {
  /// Returns every country available for the quiz.
  ///
  /// Implementations should try the network first and transparently fall back
  /// to bundled data, returning a [Failure] only when both paths fail.
  Future<Result<List<Country>>> getCountries();
}
