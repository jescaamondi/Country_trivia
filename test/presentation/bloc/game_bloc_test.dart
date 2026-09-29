import 'dart:math';

import 'package:bloc_test/bloc_test.dart';
import 'package:country_trivia/core/error/failures.dart';
import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/entities/quiz_question.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCountries extends Mock implements GetCountries {}

void main() {
  late MockGetCountries getCountries;

  const kenya = Country(name: 'Kenya', isoCode: 'ke');
  const peru = Country(name: 'Peru', isoCode: 'pe');
  const togo = Country(name: 'Togo', isoCode: 'tg');
  const chad = Country(name: 'Chad', isoCode: 'td');
  const cuba = Country(name: 'Cuba', isoCode: 'cu');
  const fiji = Country(name: 'Fiji', isoCode: 'fj');

  /// Six countries: enough to run several rounds with unique answers.
  const pool = [kenya, peru, togo, chad, cuba, fiji];

  /// Every state the bloc has emitted, in order.
  late List<GameState> emitted;

  setUp(() {
    getCountries = MockGetCountries();
    emitted = [];
  });

  GameBloc buildBloc() {
    final bloc = GameBloc(getCountries: getCountries, random: Random(7));
    bloc.stream.listen(emitted.add);
    return bloc;
  }

  void stubSuccess([List<Country> countries = pool]) {
    when(() => getCountries())
        .thenAnswer((_) async => Result.success(countries));
  }

  void stubFailure() {
    when(() => getCountries()).thenAnswer(
      (_) async => Result<List<Country>>.failure(const NetworkFailure()),
    );
  }

  /// Waits until [predicate] holds, or fails the test rather than hanging.
  Future<void> waitFor(
    GameBloc bloc,
    bool Function(GameState state) predicate,
  ) async {
    if (predicate(bloc.state)) return;
    await bloc.stream.firstWhere(predicate).timeout(const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
  }

  /// Starts a run and waits until the first flag is dealt.
  Future<void> startGame(GameBloc bloc) async {
    bloc.add(const GameStarted());
    await waitFor(bloc, (s) => s.status == GameStatus.playing);
  }

  /// Sends [event] and waits for the bloc to settle into [predicate].
  Future<void> dispatch(
    GameBloc bloc,
    GameEvent event,
    bool Function(GameState state) predicate,
  ) async {
    final before = emitted.length;
    bloc.add(event);
    await waitFor(bloc, (s) => predicate(s) && emitted.length > before);
  }

  /// The next distractor that has not already been locked out this round.
  Country wrongOptionIn(GameState state) => state.question!.options.firstWhere(
    (c) =>
        c != state.question!.answer && !state.wrongOptions.contains(c.isoCode),
  );

  group('loading', () {
    blocTest<GameBloc, GameState>(
      'emits loading before dealing the first flag',
      setUp: stubSuccess,
      build: buildBloc,
      act: (bloc) => startGame(bloc),
      expect: () => [
        isA<GameState>().having((s) => s.status, 'status', GameStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameStatus.playing)
            .having((s) => s.totalCountries, 'totalCountries', pool.length)
            .having((s) => s.solvedCount, 'solvedCount', 0)
            .having((s) => s.score, 'score', 0)
            .having((s) => s.attemptsUsed, 'attemptsUsed', 0)
            .having((s) => s.question!.options, 'option count', hasLength(4))
            .having(
              (s) => s.question!.options.contains(s.question!.answer),
              'answer present in options',
              true,
            )
            .having(
              (s) => s.question!.options.toSet(),
              'options unique',
              hasLength(4),
            ),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits failure when the pool cannot be loaded',
      setUp: stubFailure,
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted());
        await waitFor(bloc, (s) => s.status == GameStatus.failure);
      },
      expect: () => [
        isA<GameState>().having((s) => s.status, 'status', GameStatus.loading),
        isA<GameState>()
            .having((s) => s.status, 'status', GameStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', isNotEmpty),
      ],
    );

    blocTest<GameBloc, GameState>(
      'recovers when a retry succeeds',
      setUp: () {
        var calls = 0;
        when(() => getCountries()).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? Result<List<Country>>.failure(const NetworkFailure())
              : Result<List<Country>>.success(pool);
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const GameStarted());
        await waitFor(bloc, (s) => s.status == GameStatus.failure);
        await startGame(bloc);
      },
      verify: (bloc) {
        expect(bloc.state.status, GameStatus.playing);
        expect(bloc.state.totalCountries, pool.length);
      },
    );
  });

  group('non repeating questions', () {
    test('uses every country as the answer exactly once', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);

      final answers = <String>{};
      for (var i = 0; i < pool.length; i++) {
        final question = bloc.state.question!;
        expect(
          answers.add(question.answer.isoCode),
          isTrue,
          reason: '${question.answer.name} was used as the answer twice',
        );

        // While enough unused countries remain to fill three slots, none of
        // them may be a completed country. The closing rounds legitimately
        // fall back to already played countries as distractors.
        if (pool.length - i >= 4) {
          final solved = answers.toSet();
          final leaked = question.options
              .where((c) => solved.contains(c.isoCode) && c != question.answer)
              .toList();
          expect(
            leaked,
            isEmpty,
            reason: 'a completed country was reused as a distractor',
          );
        }

        await dispatch(
          bloc,
          QuizOptionSelected(question.answer),
          (s) => s.status == GameStatus.answered,
        );
        await dispatch(
          bloc,
          const QuizNextRequested(),
          (s) =>
              s.status == GameStatus.playing ||
              s.status == GameStatus.completed,
        );
      }

      expect(bloc.state.status, GameStatus.completed);
      expect(bloc.state.solvedCount, pool.length);
      expect(bloc.state.correctAnswers, pool.length);
      // A flawless run: 10 points per country.
      expect(bloc.state.score, pool.length * 10);
    });

    test('the final round still offers four options', () async {
      // Only four countries: the last question has to borrow its
      // distractors from countries that were already played.
      stubSuccess([kenya, peru, togo, chad]);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);

      for (var i = 0; i < 4; i++) {
        expect(bloc.state.question!.options, hasLength(4));
        expect(bloc.state.question!.options.toSet(), hasLength(4));

        await dispatch(
          bloc,
          QuizOptionSelected(bloc.state.question!.answer),
          (s) => s.status == GameStatus.answered,
        );
        await dispatch(
          bloc,
          const QuizNextRequested(),
          (s) =>
              s.status == GameStatus.playing ||
              s.status == GameStatus.completed,
        );
      }

      expect(bloc.state.status, GameStatus.completed);
    });
  });

  group('attempt based scoring', () {
    test('awards 10 points for a first try correct answer', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      await dispatch(
        bloc,
        QuizOptionSelected(bloc.state.question!.answer),
        (s) => s.status == GameStatus.answered,
      );

      expect(bloc.state.score, 10);
      expect(bloc.state.pointsEarned, 10);
      expect(bloc.state.correctAnswers, 1);
      expect(bloc.state.solvedCount, 1);
      expect(bloc.state.answeredCorrectly, isTrue);
    });

    test(
      'awards 8 points on the second try and locks the wrong option',
      () async {
        stubSuccess();
        final bloc = buildBloc();
        addTearDown(bloc.close);

        await startGame(bloc);
        final wrong = wrongOptionIn(bloc.state);

        await dispatch(
          bloc,
          QuizOptionSelected(wrong),
          (s) => s.attemptsUsed == 1,
        );

        expect(bloc.state.score, 0);
        expect(bloc.state.status, GameStatus.playing);
        expect(bloc.state.attemptsRemaining, 2);
        expect(bloc.state.wrongOptions, {wrong.isoCode});
        expect(bloc.state.answeredCorrectly, isNull);

        await dispatch(
          bloc,
          QuizOptionSelected(bloc.state.question!.answer),
          (s) => s.status == GameStatus.answered,
        );

        expect(bloc.state.score, 8);
        expect(bloc.state.pointsEarned, 8);
        expect(bloc.state.attemptsUsed, 2);
      },
    );

    test('awards 5 points on the third try', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);

      await dispatch(
        bloc,
        QuizOptionSelected(wrongOptionIn(bloc.state)),
        (s) => s.attemptsUsed == 1,
      );
      await dispatch(
        bloc,
        QuizOptionSelected(wrongOptionIn(bloc.state)),
        (s) => s.attemptsUsed == 2,
      );
      await dispatch(
        bloc,
        QuizOptionSelected(bloc.state.question!.answer),
        (s) => s.status == GameStatus.answered,
      );

      expect(bloc.state.score, 5);
      expect(bloc.state.pointsEarned, 5);
      expect(bloc.state.attemptsUsed, 3);
      expect(bloc.state.attemptsRemaining, 0);
      expect(bloc.state.correctAnswers, 1);
    });

    test('scores 0 and reveals the answer after three wrong guesses', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final answer = bloc.state.question!.answer;

      for (var attempt = 1; attempt <= 3; attempt++) {
        await dispatch(
          bloc,
          QuizOptionSelected(wrongOptionIn(bloc.state)),
          (s) => s.attemptsUsed == attempt,
        );
      }

      expect(bloc.state.status, GameStatus.answered);
      expect(bloc.state.answeredCorrectly, isFalse);
      expect(bloc.state.score, 0);
      expect(bloc.state.pointsEarned, 0);
      expect(bloc.state.attemptsRemaining, 0);
      expect(bloc.state.correctAnswers, 0);
      // The flag still counts as played so the run can finish.
      expect(bloc.state.solvedCount, 1);
      expect(bloc.state.wrongOptions, hasLength(3));
      // The answer is on screen for the player to learn from.
      expect(bloc.state.question!.answer, answer);
    });

    test('a failed country is not offered as the answer again', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final failed = bloc.state.question!.answer;

      for (var attempt = 1; attempt <= 3; attempt++) {
        await dispatch(
          bloc,
          QuizOptionSelected(wrongOptionIn(bloc.state)),
          (s) => s.attemptsUsed == attempt,
        );
      }
      await dispatch(
        bloc,
        const QuizNextRequested(),
        (s) => s.status == GameStatus.playing,
      );

      expect(bloc.state.question!.answer, isNot(failed));
    });
  });

  group('input guards', () {
    test('ignores taps on an option already known to be wrong', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final wrong = wrongOptionIn(bloc.state);

      await dispatch(
        bloc,
        QuizOptionSelected(wrong),
        (s) => s.attemptsUsed == 1,
      );
      final emittedAfterFirst = emitted.length;

      bloc.add(QuizOptionSelected(wrong));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.attemptsUsed, 1);
      expect(bloc.state.wrongOptions, {wrong.isoCode});
      expect(
        emitted.length,
        emittedAfterFirst,
        reason: 'no state should be emitted',
      );
    });

    test('ignores taps once the round is already resolved', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final wrong = wrongOptionIn(bloc.state);

      await dispatch(
        bloc,
        QuizOptionSelected(bloc.state.question!.answer),
        (s) => s.status == GameStatus.answered,
      );
      final scoreAfterCorrect = bloc.state.score;
      final emittedAfterCorrect = emitted.length;

      bloc.add(QuizOptionSelected(wrong));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.score, scoreAfterCorrect);
      expect(bloc.state.wrongOptions, isEmpty);
      expect(bloc.state.status, GameStatus.answered);
      expect(
        emitted.length,
        emittedAfterCorrect,
        reason: 'no state should be emitted',
      );
    });

    test('a resolved round still advances on an explicit next', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final first = bloc.state.question!.answer;

      await dispatch(
        bloc,
        QuizOptionSelected(first),
        (s) => s.status == GameStatus.answered,
      );
      await dispatch(
        bloc,
        const QuizNextRequested(),
        (s) => s.status == GameStatus.playing,
      );

      expect(bloc.state.question!.answer, isNot(first));
    });

    test('ignores next before the round is answered', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      final first = bloc.state.question!.answer;

      bloc.add(const QuizNextRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.question!.answer, first);
      expect(bloc.state.solvedCount, 0);
    });
  });

  group('reset', () {
    test('restores the full pool and clears the score', () async {
      stubSuccess();
      final bloc = buildBloc();
      addTearDown(bloc.close);

      await startGame(bloc);
      await dispatch(
        bloc,
        QuizOptionSelected(bloc.state.question!.answer),
        (s) => s.status == GameStatus.answered,
      );
      await dispatch(
        bloc,
        const QuizNextRequested(),
        (s) => s.status == GameStatus.playing,
      );
      expect(bloc.state.score, 10);

      await dispatch(bloc, const GameResetRequested(), (s) => s.score == 0);

      expect(bloc.state.score, 0);
      expect(bloc.state.solvedCount, 0);
      expect(bloc.state.correctAnswers, 0);
      expect(bloc.state.totalCountries, pool.length);
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.attemptsUsed, 0);
      expect(bloc.state.wrongOptions, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    test('a reset run can reach the end again', () async {
      stubSuccess([kenya, peru, togo, chad]);
      final bloc = buildBloc();
      addTearDown(bloc.close);

      Future<void> playOut() async {
        for (var i = 0; i < 4; i++) {
          await dispatch(
            bloc,
            QuizOptionSelected(bloc.state.question!.answer),
            (s) => s.status == GameStatus.answered,
          );
          await dispatch(
            bloc,
            const QuizNextRequested(),
            (s) =>
                s.status == GameStatus.completed ||
                s.status == GameStatus.playing,
          );
        }
      }

      await startGame(bloc);
      await playOut();
      expect(bloc.state.status, GameStatus.completed);

      await dispatch(
        bloc,
        const GameResetRequested(),
        (s) => s.status == GameStatus.playing,
      );
      expect(bloc.state.totalCountries, 4);

      await playOut();
      expect(bloc.state.status, GameStatus.completed);
      expect(bloc.state.score, 40);
    });
  });

  group('QuizQuestion', () {
    test('always offers exactly one correct answer and three distractors', () {
      final question = QuizQuestion.create(
        answer: kenya,
        distractorPool: pool,
        fallbackPool: const [],
        random: Random(3),
      );

      expect(question.options, hasLength(4));
      expect(question.options.where((c) => c == kenya), hasLength(1));
      expect(question.options.toSet(), hasLength(4));
    });

    test('falls back to completed countries when the pool runs dry', () {
      final question = QuizQuestion.create(
        answer: kenya,
        distractorPool: const [],
        fallbackPool: pool,
        random: Random(3),
      );

      expect(question.options, hasLength(4));
      expect(question.options, contains(kenya));
      expect(question.options.toSet(), hasLength(4));
    });

    test('never offers the answer as its own distractor', () {
      final question = QuizQuestion.create(
        answer: kenya,
        distractorPool: [kenya, peru],
        fallbackPool: [kenya, peru, togo],
        random: Random(5),
      );

      final distractors = question.options.where((c) => c != kenya);
      expect(distractors.toSet(), hasLength(distractors.length));
    });
  });
}
