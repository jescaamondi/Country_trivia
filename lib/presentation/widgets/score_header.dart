import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:country_trivia/domain/entities/attempt_scoring.dart';
import 'package:country_trivia/presentation/bloc/game/game_state.dart';
import 'package:flutter/material.dart';

/// The always visible readout: score, progress and remaining attempts.
class ScoreHeader extends StatelessWidget {
  const ScoreHeader({super.key, required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.stars_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'SCORE',
                value: '${state.score}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.public_rounded,
                iconColor: AppColors.primary,
                label: 'SOLVED',
                value: '${state.solvedCount} / ${state.totalCountries}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProgressBar(progress: state.progress),
        const SizedBox(height: 16),
        _AttemptsRow(state: state),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 8,
          backgroundColor: AppColors.border,
          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
  }
}

/// Shows the three attempt pips, spent ones dimmed out.
class _AttemptsRow extends StatelessWidget {
  const _AttemptsRow({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final remaining = state.attemptsRemaining;

    return Row(
      children: [
        const Icon(
          Icons.bolt_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text('Attempts left', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 12),
        for (var i = 0; i < AttemptScoring.maxAttempts; i++) ...[
          _AttemptPip(spent: i < state.attemptsUsed),
          if (i < AttemptScoring.maxAttempts - 1) const SizedBox(width: 6),
        ],
        const Spacer(),
        if (state.status == GameStatus.playing && remaining > 0)
          Text(
            'worth ${state.pointsOnTheLine} pts',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
      ],
    );
  }
}

class _AttemptPip extends StatelessWidget {
  const _AttemptPip({required this.spent});

  final bool spent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 10,
      width: 28,
      decoration: BoxDecoration(
        color: spent ? AppColors.disabled : AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
