import 'package:country_trivia/core/theme/app_theme.dart';
import 'package:country_trivia/domain/entities/country.dart';
import 'package:flutter/material.dart';

/// Visual state of a single answer option.
enum OptionVisualState {
  /// Pickable.
  idle,

  /// Chosen and wrong: red, and no longer tappable.
  wrong,

  /// The correct answer, revealed either by a correct guess or by running out
  /// of attempts.
  correct,
}

/// A tappable answer in the multiple choice list.
class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.country,
    required this.visualState,
    required this.onTap,
  });

  final Country country;
  final OptionVisualState visualState;
  final VoidCallback? onTap;

  bool get _isDisabled => visualState != OptionVisualState.idle;

  @override
  Widget build(BuildContext context) {
    final (background, border, foreground) = switch (visualState) {
      OptionVisualState.idle => (
        Colors.white,
        AppColors.border,
        AppColors.textPrimary,
      ),
      OptionVisualState.wrong => (
        AppColors.dangerSurface,
        AppColors.danger,
        AppColors.danger,
      ),
      OptionVisualState.correct => (
        AppColors.successSurface,
        AppColors.success,
        AppColors.success,
      ),
    };

    return Semantics(
      button: !_isDisabled,
      enabled: !_isDisabled,
      selected: visualState == OptionVisualState.correct,
      label: country.name,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: _isDisabled ? 2 : 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isDisabled ? null : onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  if (_isDisabled) ...[
                    Icon(_icon, color: foreground, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      country.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _isDisabled
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _isDisabled
                            ? foreground
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => visualState == OptionVisualState.correct
      ? Icons.check_circle
      : Icons.cancel;
}
