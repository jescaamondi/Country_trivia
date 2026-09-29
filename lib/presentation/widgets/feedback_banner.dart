import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:flutter/material.dart';

/// Result strip shown once a round is resolved.
///
/// Either congratulates the player and states how many points the answer was
/// worth, or reveals the answer after all attempts were used.
class FeedbackBanner extends StatelessWidget {
  const FeedbackBanner({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final isCorrect = state.isCorrect;
    final answer = state.question?.answer;
    final color = isCorrect ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successSurface : AppColors.dangerSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect
                      ? 'Correct! +${state.pointsEarned} points'
                      : 'Out of attempts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isCorrect)
                  _RevealAnswer(answer: answer, color: color)
                else
                  Text(
                    _praise[state.solvedCount % _praise.length],
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _praise = [
    'Nice recognition!',
    'Sharp eye!',
    'Flag master!',
    'Spot on!',
  ];
}

class _RevealAnswer extends StatelessWidget {
  const _RevealAnswer({required this.answer, required this.color});

  final Country? answer;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        children: [
          const TextSpan(text: 'The flag was '),
          TextSpan(
            text: answer?.name ?? 'unknown',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
