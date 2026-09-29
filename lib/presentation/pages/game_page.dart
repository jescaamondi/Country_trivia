import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:country_trivia/presentation/pages/game_completed_page.dart';
import 'package:country_trivia/presentation/pages/status_views.dart';
import 'package:country_trivia/presentation/widgets/answer_option.dart';
import 'package:country_trivia/presentation/widgets/feedback_banner.dart';
import 'package:country_trivia/presentation/widgets/flag_image.dart';
import 'package:country_trivia/presentation/widgets/score_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The quiz screen: flag, answer options, score and progress.
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flag Trivia'),
        actions: [
          IconButton(
            tooltip: 'Reset game',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () =>
                context.read<GameBloc>().add(const GameResetRequested()),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<GameBloc, GameState>(
          listenWhen: (previous, current) =>
              current.status == GameStatus.completed &&
              previous.status != GameStatus.completed,
          listener: (context, _) {
            Navigator.of(context).push(GameCompletedPage.route());
          },
          builder: (context, state) {
            return switch (state.status) {
              GameStatus.initial || GameStatus.loading => const LoadingView(),
              GameStatus.failure => ErrorView(
                message: state.errorMessage ?? 'Countries could not be loaded.',
                onRetry: () =>
                    context.read<GameBloc>().add(const GameStarted()),
              ),
              GameStatus.completed => const _CompletedPlaceholder(),
              GameStatus.playing || GameStatus.answered => _QuizBody(
                state: state,
                onOptionSelected: (country) =>
                    context.read<GameBloc>().add(QuizOptionSelected(country)),
                onNext: () =>
                    context.read<GameBloc>().add(const QuizNextRequested()),
              ),
            };
          },
        ),
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.state,
    required this.onOptionSelected,
    required this.onNext,
  });

  final GameState state;
  final ValueChanged<Country> onOptionSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final question = state.question;
    if (question == null) return const LoadingView();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScoreHeader(state: state),
                  const SizedBox(height: 24),
                  Text(
                    'Which country does this flag belong to?',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: FlagImage(isoCode: question.answer.isoCode),
                  ),
                  const SizedBox(height: 20),
                  for (final option in question.options) ...[
                    AnswerOption(
                      key: ValueKey('option-${option.isoCode}'),
                      country: option,
                      visualState: _visualStateFor(state, option),
                      onTap: () => onOptionSelected(option),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (state.canAdvance) ...[
                    const SizedBox(height: 6),
                    FeedbackBanner(state: state),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('next_button'),
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next flag'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Maps a round's internal bookkeeping onto what the option should look
  /// like: wrong once guessed, correct once the round is resolved, neutral
  /// otherwise.
  static OptionVisualState _visualStateFor(GameState state, option) {
    if (state.status == GameStatus.answered) {
      return option == state.question!.answer
          ? OptionVisualState.correct
          : OptionVisualState.wrong;
    }
    if (state.wrongOptions.contains(option.isoCode)) {
      return OptionVisualState.wrong;
    }
    return OptionVisualState.idle;
  }
}

/// Shown underneath the results route, in case it is dismissed.
class _CompletedPlaceholder extends StatelessWidget {
  const _CompletedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, size: 56),
          const SizedBox(height: 12),
          Text('Game completed', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: FilledButton(
              onPressed: () =>
                  Navigator.of(context).push(GameCompletedPage.route()),
              child: const Text('View results'),
            ),
          ),
        ],
      ),
    );
  }
}
