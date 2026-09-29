import 'package:country_trivia/core/error/failures.dart';
import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/repositories/country_repository.dart';

/// Fetches the country pool the game is built from.
///
/// A use case rather than a direct repository call so the bloc depends on an
/// intention ("give me the countries") instead of a data source.
class GetCountries {
  const GetCountries(this._repository);

  final CountryRepository _repository;

  /// The quiz needs at least one correct answer plus three distractors.
  static const int minimumUsableCountries = 4;

  Future<Result<List<Country>>> call() async {
    final result = await _repository.getCountries();

    return switch (result) {
      Success<List<Country>>(value: final countries)
          when countries.length < minimumUsableCountries =>
        Result<List<Country>>.failure(
          const ParseFailure(
            'Not enough countries were returned to build a quiz.',
          ),
        ),
      _ => result,
    };
  }
}
