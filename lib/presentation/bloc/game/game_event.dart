import 'package:country_trivia/domain/entities/country.dart';
import 'package:equatable/equatable.dart';

/// Events accepted by [GameBloc].
sealed class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object?> get props => [];
}

/// Load the country pool and start a new run. Also used to retry after a
/// failure.
class GameStarted extends GameEvent {
  const GameStarted();
}

/// A country was tapped as an answer for the current flag.
class QuizOptionSelected extends GameEvent {
  const QuizOptionSelected(this.country);

  final Country country;

  @override
  List<Object?> get props => [country];
}

/// Dismiss the current round's feedback and deal the next flag.
class QuizNextRequested extends GameEvent {
  const QuizNextRequested();
}

/// Clear the score and restore the full country pool.
class GameResetRequested extends GameEvent {
  const GameResetRequested();
}

/// Internal: the country pool finished loading.
class GameCountriesLoaded extends GameEvent {
  const GameCountriesLoaded(this.countries);

  final List<Country> countries;

  @override
  List<Object?> get props => [countries];
}

/// Internal: the country pool could not be loaded.
class GameLoadFailed extends GameEvent {
  const GameLoadFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
