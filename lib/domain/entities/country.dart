import 'package:equatable/equatable.dart';

/// A country that can be used as the answer to a question.
class Country extends Equatable {
  const Country({required this.name, required this.isoCode});

  /// The common (English) country name, e.g. `Kenya`.
  final String name;

  /// The lowercase ISO 3166-1 alpha-2 code, e.g. `ke`.
  ///
  /// FlagCDN keys flags off this value, so it is normalised on construction.
  final String isoCode;

  @override
  List<Object?> get props => [name, isoCode];

  @override
  String toString() => 'Country($name, $isoCode)';
}
