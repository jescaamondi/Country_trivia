import 'package:country_trivia/core/error/exceptions.dart';
import 'package:country_trivia/data/datasources/country_remote_data_source.dart';
import 'package:country_trivia/data/models/country_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpCountryRemoteDataSource.parseCountries', () {
    test('reads the {data: [...]} envelope', () {
      final countries = HttpCountryRemoteDataSource.parseCountries({
        'error': false,
        'msg': 'ok',
        'data': [
          {'name': 'Kenya', 'Iso2': 'KE', 'Iso3': 'KEN'},
          {'name': 'Peru', 'Iso2': 'PE', 'Iso3': 'PER'},
        ],
      });

      expect(countries, hasLength(2));
      expect(countries.first.name, 'Kenya');
      expect(countries.first.isoCode, 'ke');
    });

    test('reads a bare array payload', () {
      final countries = HttpCountryRemoteDataSource.parseCountries({
        'data': [
          {'country': 'Fiji', 'iso2': 'FJ'},
        ],
      });

      expect(countries.single.name, 'Fiji');
    });

    test('reads a restcountries style {data: {countries: [...]}} payload', () {
      final countries = HttpCountryRemoteDataSource.parseCountries({
        'data': {
          'countries': [
            {
              'name': {'common': 'Togo'},
              'cca2': 'TG',
            },
          ],
        },
      });

      expect(countries.single.isoCode, 'tg');
    });

    test('de-duplicates repeated iso codes', () {
      final countries = HttpCountryRemoteDataSource.parseCountries({
        'data': [
          {'name': 'Kenya', 'Iso2': 'KE'},
          {'name': 'Kenya (dup)', 'Iso2': 'KE'},
        ],
      });

      expect(countries, hasLength(1));
    });

    test('skips entries missing a name or a two letter code', () {
      final countries = HttpCountryRemoteDataSource.parseCountries({
        'data': [
          {'name': 'Kenya', 'Iso2': 'KE'},
          {'Iso2': 'XX'},
          {'name': 'Nowhere', 'Iso2': 'XXX'},
        ],
      });

      expect(countries, hasLength(1));
    });

    test('throws when the payload is not a list', () {
      expect(
        () => HttpCountryRemoteDataSource.parseCountries({
          'data': {'a': 1},
        }),
        throwsA(isA<ParseException>()),
      );
    });

    test('throws when nothing usable is present', () {
      expect(
        () => HttpCountryRemoteDataSource.parseCountries({'data': <Object?>[]}),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('CountryModel', () {
    test('lowercases the iso code', () {
      final model = CountryModel.fromJson({'name': 'Cuba', 'Iso2': 'CU'});
      expect(model?.isoCode, 'cu');
    });

    test('prefers an explicit name over an official name', () {
      final model = CountryModel.fromJson({
        'official': 'Republic of Kenya',
        'name': 'Kenya',
        'cca2': 'KE',
      });
      expect(model?.name, 'Kenya');
    });

    test('returns null when the code is not two characters', () {
      expect(CountryModel.fromJson({'name': 'Kenya', 'iso2': 'KEN'}), isNull);
    });

    test('ignores blank values', () {
      expect(CountryModel.fromJson({'name': '  ', 'iso2': 'KE'}), isNull);
    });
  });
}
