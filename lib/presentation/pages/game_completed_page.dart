import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:country_trivia/presentation/bloc/game/game_bloc.dart';
import 'package:country_trivia/presentation/bloc/game/game_event.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Final results, shown once every country in the pool has been played.
class GameCompletedPage extends StatelessWidget {
  const GameCompletedPage({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const GameCompletedPage());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: SafeArea(
        child: BlocBuilder<GameBloc, GameState>(
          builder: (context, state) {
            final total = state.totalCountries;
            final accuracy = total == 0 ? 0.0 : state.correctAnswers / total;
            final maxScore = state.maxScore;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      const _Trophy(),
                      const SizedBox(height: 20),
                      Text(
                        'Game Completed',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You played all $total countries. '
                        'Here is how you did.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _ScoreCard(score: state.score, maxScore: maxScore),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.check_circle_rounded,
                              color: AppColors.success,
                              label: 'Correct',
                              value: '${state.correctAnswers}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.percent_rounded,
                              color: AppColors.primary,
                              label: 'Accuracy',
                              value: '${(accuracy * 100).round()}%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        key: const Key('reset_button'),
                        onPressed: () {
                          context.read<GameBloc>().add(
                            const GameResetRequested(),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Reset game'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Trophy extends StatelessWidget {
  const _Trophy();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      width: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFDE68A),
            const Color(0xFFF59E0B).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 52,
        color: Colors.white,
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.maxScore});

  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text(
            'FINAL SCORE',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'out of a possible $maxScore',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
