import 'dart:math';

import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/attempt_scoring.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/entities/quiz_question.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns the whole run: the country pool, question dealing, attempt tracking
/// and scoring.
///
/// The pools that are not needed for rendering ([_pool], [_completed],
/// [_all]) are held as private fields so [GameState] stays cheap to compare
/// and widgets never rebuild because of them.
class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc({required GetCountries getCountries, Random? random})
    // ignore: prefer_initializing_formals
    : _getCountries = getCountries,
      _random = random ?? Random(),
      super(const GameState()) {
    on<GameStarted>(_onStarted);
    on<GameCountriesLoaded>(_onCountriesLoaded);
    on<GameLoadFailed>(_onLoadFailed);
    on<QuizOptionSelected>(_onOptionSelected);
    on<QuizNextRequested>(_onNextRequested);
    on<GameResetRequested>(_onResetRequested);
  }

  final GetCountries _getCountries;
  final Random _random;

  /// Every country in the run, in load order. Restored by a reset.
  List<Country> _all = const [];

  /// Countries that can still become the answer, shuffled.
  List<Country> _pool = const [];

  /// Countries already played, used to fill distractors in the final rounds.
  List<Country> _completed = const [];

  Future<void> _onStarted(GameStarted event, Emitter<GameState> emit) async {
    emit(state.copyWith(status: GameStatus.loading, errorMessage: null));

    final result = await _getCountries();
    switch (result) {
      case Success<List<Country>>(value: final countries):
        add(GameCountriesLoaded(countries));
      case FailureResult<List<Country>>(failure: final failure):
        add(GameLoadFailed(failure.message));
    }
  }

  void _onCountriesLoaded(GameCountriesLoaded event, Emitter<GameState> emit) {
    _startRun(event.countries);
    emit(_nextRoundState(score: 0, correctAnswers: 0));
  }

  void _onLoadFailed(GameLoadFailed event, Emitter<GameState> emit) {
    _pool = const [];
    _completed = const [];
    _all = const [];
    emit(GameState(status: GameStatus.failure, errorMessage: event.message));
  }

  void _onOptionSelected(QuizOptionSelected event, Emitter<GameState> emit) {
    final question = state.question;
    if (!state.canAnswer || question == null) return;

    final selected = event.country;

    // Guard against a repeated tap on an option that is already wrong.
    if (state.wrongOptions.contains(selected.isoCode)) return;

    final attempt = state.attemptsUsed + 1;

    if (selected == question.answer) {
      final points = AttemptScoring.pointsForAttempt(attempt);
      _completed = [..._completed, question.answer];

      emit(
        state.copyWith(
          status: GameStatus.answered,
          solvedCount: _completed.length,
          correctAnswers: state.correctAnswers + 1,
          score: state.score + points,
          attemptsUsed: attempt,
          answeredCorrectly: true,
          pointsEarned: points,
        ),
      );
      return;
    }

    final wrongOptions = {...state.wrongOptions, selected.isoCode};
    final attemptsUsed = attempt;

    if (attemptsUsed >= AttemptScoring.maxAttempts) {
      // Out of attempts: 0 points, the answer gets revealed, move on.
      emit(
        state.copyWith(
          status: GameStatus.answered,
          solvedCount: _completed.length + 1,
          attemptsUsed: attemptsUsed,
          wrongOptions: wrongOptions,
          answeredCorrectly: false,
          pointsEarned: 0,
        ),
      );
      return;
    }

    // Still in the fight: the wrong option is locked out for the round.
    emit(
      state.copyWith(attemptsUsed: attemptsUsed, wrongOptions: wrongOptions),
    );
  }

  void _onNextRequested(QuizNextRequested event, Emitter<GameState> emit) {
    if (!state.canAdvance) return;

    if (_pool.isEmpty) {
      emit(
        GameState(
          status: GameStatus.completed,
          solvedCount: _all.length,
          correctAnswers: state.correctAnswers,
          totalCountries: _all.length,
          score: state.score,
        ),
      );
      return;
    }

    emit(
      _nextRoundState(score: state.score, correctAnswers: state.correctAnswers),
    );
  }

  void _onResetRequested(GameResetRequested event, Emitter<GameState> emit) {
    if (_all.isEmpty) return;
    _startRun(_all);
    emit(_nextRoundState(score: 0, correctAnswers: 0));
  }

  /// Restores every country to the pool and clears the run totals.
  void _startRun(List<Country> countries) {
    _all = List.unmodifiable(countries);
    _pool = List<Country>.of(countries)..shuffle(_random);
    _completed = const [];
  }

  /// Deals the next flag and builds the state for the opening of a round.
  ///
  /// The running [score] and [correctAnswers] are threaded through from the
  /// caller's state; only the per round fields are reset here.
  GameState _nextRoundState({required int score, required int correctAnswers}) {
    final answer = _pool.removeAt(0);
    final question = QuizQuestion.create(
      answer: answer,
      distractorPool: _pool,
      fallbackPool: _completed,
      random: _random,
    );

    return GameState(
      status: GameStatus.playing,
      question: question,
      solvedCount: _completed.length,
      correctAnswers: correctAnswers,
      totalCountries: _all.length,
      score: score,
    );
  }
}
