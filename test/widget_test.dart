import 'dart:math';

import 'package:country_trivia/core/error/result.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/domain/repositories/country_repository.dart';
import 'package:country_trivia/domain/usecases/get_countries.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:country_trivia/presentation/pages/game_page.dart';
import 'package:country_trivia/presentation/widgets/answer_option.dart';
import 'package:country_trivia/presentation/widgets/flag_image.dart';
import 'package:country_trivia/presentation/widgets/score_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backs the app with a fixed pool so the smoke test never touches the
/// network.
class _StubRepository implements CountryRepository {
  @override
  Future<Result<List<Country>>> getCountries() async =>
      Result<List<Country>>.success(const [
        Country(name: 'Kenya', isoCode: 'ke'),
        Country(name: 'Peru', isoCode: 'pe'),
        Country(name: 'Togo', isoCode: 'tg'),
        Country(name: 'Chad', isoCode: 'td'),
      ]);
}

void main() {
  GameBloc buildBloc() =>
      GameBloc(getCountries: GetCountries(_StubRepository()), random: Random(5))
        ..add(const GameStarted());

  Widget wrap(GameBloc bloc) => BlocProvider<GameBloc>.value(
    value: bloc,
    child: const MaterialApp(home: GamePage()),
  );

  /// The flag image is network backed and never resolves under `flutter_test`,
  /// so `pumpAndSettle` would hang on the placeholder spinner. Pump a fixed
  /// number of frames instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Scrolls [finder] into view before tapping it: the quiz is a scrolling
  /// column, so options can start below the fold in the test viewport.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
  }

  testWidgets('boots straight into a playable round', (tester) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(wrap(bloc));
    await settle(tester);

    expect(find.byType(GamePage), findsOneWidget);
    expect(find.text('Flag Trivia'), findsOneWidget);
    expect(find.byType(FlagImage), findsOneWidget);
    expect(find.byType(ScoreHeader), findsOneWidget);
    expect(find.byType(AnswerOption), findsNWidgets(4));
    expect(find.text('0 / 4'), findsOneWidget);
    expect(bloc.state.status, GameStatus.playing);
  });

  testWidgets('the header tracks progress and the points still on the line', (
    tester,
  ) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await tester.pumpWidget(wrap(bloc));
    await settle(tester);

    // A wrong guess must cost an attempt and drop the round to 8 points.
    final wrong = bloc.state.question!.options.firstWhere(
      (c) => c != bloc.state.question!.answer,
    );
    await tapVisible(tester, find.text(wrong.name));
    await settle(tester);

    expect(bloc.state.attemptsUsed, 1);
    expect(find.text('Attempts left'), findsOneWidget);
    expect(find.text('worth 8 pts'), findsOneWidget);
    expect(find.text('0 / 4'), findsOneWidget);
  });
}
