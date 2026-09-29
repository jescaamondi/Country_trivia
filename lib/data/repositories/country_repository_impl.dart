import 'package:country_trivia/core/error/exceptions.dart';
import 'package:country_trivia/core/error/failures.dart';
import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/data/datasources/country_local_data_source.dart';
import 'package:country_trivia/data/datasources/country_remote_data_source.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/repositories/country_repository.dart';

/// Network-first repository with a bundled offline fallback.
///
/// This is the only place that knows how transport errors map onto domain
/// failures, keeping `try`/`catch` out of the presentation layer.
class CountryRepositoryImpl implements CountryRepository {
  const CountryRepositoryImpl({
    required CountryRemoteDataSource remoteDataSource,
    required CountryLocalDataSource localDataSource,
  }) : _remote = remoteDataSource,
       _local = localDataSource;

  final CountryRemoteDataSource _remote;
  final CountryLocalDataSource _local;

  @override
  Future<Result<List<Country>>> getCountries() async {
    try {
      final countries = await _remote.fetchCountries();
      return Result<List<Country>>.success(countries);
    } on ApiException catch (e) {
      return _fallback(e.message);
    } on ParseException catch (e) {
      return _fallback(e.message);
    } on Exception catch (e) {
      return _fallback(e.toString());
    }
  }

  /// Degrades to the bundled snapshot, only surfacing a failure if that is
  /// empty too.
  Result<List<Country>> _fallback(String remoteMessage) {
    final local = _local.loadCountries();
    if (local.isEmpty) {
      return Result<List<Country>>.failure(
        NetworkFailure('Could not load countries. $remoteMessage'),
      );
    }
    return Result<List<Country>>.success(local);
  }
}
