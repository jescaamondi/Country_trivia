import 'package:country_trivia/core/error/exceptions.dart';
import 'package:country_trivia/core/error/failures.dart';
import 'package:country_trivia/data/datasources/country_local_data_source.dart';
import 'package:country_trivia/data/datasources/country_remote_data_source.dart';
import 'package:country_trivia/data/repositories/country_repository_impl.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements CountryRemoteDataSource {}

class MockLocal extends Mock implements CountryLocalDataSource {}

void main() {
  late MockRemote remote;
  late MockLocal local;

  const kenya = Country(name: 'Kenya', isoCode: 'ke');

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    when(() => local.loadCountries()).thenReturn([kenya]);
  });

  CountryRepositoryImpl build() =>
      CountryRepositoryImpl(remoteDataSource: remote, localDataSource: local);

  group('CountryRepositoryImpl', () {
    test('returns the remote pool on success', () async {
      when(() => remote.fetchCountries()).thenAnswer((_) async => [kenya]);

      final result = await build().getCountries();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, [kenya]);
      verifyNever(local.loadCountries);
    });

    test('falls back to bundled data when the network throws', () async {
      when(() => remote.fetchCountries())
          .thenThrow(const ApiException('offline'));

      final result = await build().getCountries();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, [kenya]);
    });

    test('falls back when the payload is unparseable', () async {
      when(() => remote.fetchCountries())
          .thenThrow(const ParseException('bad shape'));

      final result = await build().getCountries();

      expect(result.isSuccess, isTrue);
    });

    test('fails only when the fallback is empty too', () async {
      when(() => local.loadCountries()).thenReturn([]);
      when(() => remote.fetchCountries())
          .thenThrow(const ApiException('offline'));

      final result = await build().getCountries();

      expect(result.isSuccess, isFalse);
      expect(result.failureOrNull, isA<Failure>());
    });
  });

  group('GetCountries', () {
    test('rejects a pool too small to build a question', () async {
      when(
        () => remote.fetchCountries(),
      ).thenAnswer((_) async => const [Country(name: 'Kenya', isoCode: 'ke')]);

      final result = await GetCountries(build())();

      expect(result.isSuccess, isFalse);
      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test('accepts a pool of exactly four', () async {
      const four = [
        Country(name: 'Kenya', isoCode: 'ke'),
        Country(name: 'Peru', isoCode: 'pe'),
        Country(name: 'Togo', isoCode: 'tg'),
        Country(name: 'Cuba', isoCode: 'cu'),
      ];
      when(() => remote.fetchCountries()).thenAnswer((_) async => four);

      final result = await GetCountries(build())();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, four);
    });
  });
}
