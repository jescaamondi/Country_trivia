import 'dart:math';

import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/repositories/country_repository.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:country_trivia/presentation/pages/game_completed_page.dart';
import 'package:country_trivia/presentation/pages/game_page.dart';
import 'package:country_trivia/presentation/widgets/answer_option.dart';
import 'package:country_trivia/presentation/widgets/flag_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCountryRepository implements CountryRepository {
  FakeCountryRepository(this.countries);

  final List<Country> countries;

  @override
  Future<Result<List<Country>>> getCountries() async =>
      Result<List<Country>>.success(countries);
}

void main() {
  const pool = [
    Country(name: 'Kenya', isoCode: 'ke'),
    Country(name: 'Peru', isoCode: 'pe'),
    Country(name: 'Togo', isoCode: 'tg'),
    Country(name: 'Chad', isoCode: 'td'),
  ];

  Widget wrap(GameBloc bloc, Widget child) => BlocProvider<GameBloc>.value(
    value: bloc,
    child: MaterialApp(home: child),
  );

  GameBloc buildBloc() => GameBloc(
    getCountries: GetCountries(FakeCountryRepository(pool)),
    random: Random(11),
  );

  /// The flag image is network backed. `flutter_test` stubs the HTTP layer, so
  /// an image that is still resolving shows its loading spinner, and an
  /// indeterminate spinner schedules frames forever. `pumpAndSettle` would
  /// therefore never return, so pump a fixed number of frames instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls [finder] into view before tapping it, since the quiz is a
  /// scrolling column and options can start below the fold.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  Future<void> tapOption(WidgetTester tester, String name) =>
      tapVisible(tester, find.text(name));

  group('AnswerOption', () {
    testWidgets('calls onTap only while idle', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOption(
              country: pool.first,
              visualState: OptionVisualState.idle,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Kenya'));
      expect(taps, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerOption(
              country: pool.first,
              visualState: OptionVisualState.wrong,
              onTap: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Kenya'));
      expect(taps, 1, reason: 'locked options must not be tappable');
    });
  });

  group('GamePage', () {
    testWidgets('renders the flag, four options and the progress readout', (
      tester,
    ) async {
      final bloc = buildBloc()..add(const GameStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(wrap(bloc, const GamePage()));
      await settle(tester);

      expect(find.text('Flag Trivia'), findsOneWidget);
      expect(find.byType(FlagImage), findsOneWidget);
      expect(find.byType(AnswerOption), findsNWidgets(4));
      expect(find.text('0 / 4'), findsOneWidget);
      expect(find.text('Attempts left'), findsOneWidget);
    });

    testWidgets('marks a wrong guess red and hides the next button', (
      tester,
    ) async {
      final bloc = buildBloc()..add(const GameStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(wrap(bloc, const GamePage()));
      await settle(tester);

      final wrong = bloc.state.question!.options.firstWhere(
        (c) => c != bloc.state.question!.answer,
      );

      await tapOption(tester, wrong.name);
      await settle(tester);

      final tile = tester.widget<AnswerOption>(
        find.byKey(ValueKey('option-${wrong.isoCode}')),
      );
      expect(tile.visualState, OptionVisualState.wrong);
      expect(find.byKey(const Key('next_button')), findsNothing);
      expect(bloc.state.score, 0);
      expect(bloc.state.attemptsRemaining, 2);
    });

    testWidgets('scores, reveals the answer and advances on a correct guess', (
      tester,
    ) async {
      final bloc = buildBloc()..add(const GameStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(wrap(bloc, const GamePage()));
      await settle(tester);

      final answer = bloc.state.question!.answer;
      await tapOption(tester, answer.name);
      await settle(tester);

      expect(find.text('Correct! +10 points'), findsOneWidget);
      expect(find.byKey(const Key('next_button')), findsOneWidget);
      expect(find.text('10'), findsOneWidget);

      final correctTile = tester.widget<AnswerOption>(
        find.byKey(ValueKey('option-${answer.isoCode}')),
      );
      expect(correctTile.visualState, OptionVisualState.correct);

      await tapVisible(tester, find.byKey(const Key('next_button')));
      await settle(tester);

      expect(bloc.state.score, 10);
      expect(bloc.state.solvedCount, 1);
      expect(bloc.state.status, GameStatus.playing);
      expect(bloc.state.question!.answer, isNot(answer));
    });

    testWidgets('reaches the results screen and can reset', (tester) async {
      final bloc = buildBloc()..add(const GameStarted());
      addTearDown(bloc.close);

      await tester.pumpWidget(wrap(bloc, const GamePage()));
      await settle(tester);

      // Answer everything correctly.
      while (bloc.state.status != GameStatus.completed) {
        final answer = bloc.state.question!.answer;
        await tapOption(tester, answer.name);
        await settle(tester);
        await tapVisible(tester, find.byKey(const Key('next_button')));
        await settle(tester);
      }

      expect(find.byType(GameCompletedPage), findsOneWidget);
      expect(find.text('Game Completed'), findsOneWidget);
      expect(
        find.text('You played all 4 countries. Here is how you did.'),
        findsOneWidget,
      );
      expect(find.text('40'), findsOneWidget); // 4 x 10
      expect(find.text('100%'), findsOneWidget);

      await tapVisible(tester, find.byKey(const Key('reset_button')));
      await settle(tester);

      expect(find.byType(GameCompletedPage), findsNothing);
      expect(bloc.state.score, 0);
      expect(bloc.state.solvedCount, 0);
      expect(bloc.state.status, GameStatus.playing);
    });
  });
}
