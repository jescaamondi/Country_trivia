import 'dart:math';

import 'package:country_trivia/domain/entities/country.dart';
import 'package:equatable/equatable.dart';

/// A single multiple choice question: one correct country plus three
/// distractors, presented in a shuffled order.
class QuizQuestion extends Equatable {
  const QuizQuestion({required this.answer, required this.options});

  /// Builds a question from a pool, choosing distractors at random.
  ///
  /// [distractorPool] holds the countries that have not been used as an answer
  /// yet. When it cannot supply three options on its own — which only happens
  /// in the closing rounds — the remainder is filled from [fallbackPool] so
  /// the final questions are still playable.
  factory QuizQuestion.create({
    required Country answer,
    required List<Country> distractorPool,
    required List<Country> fallbackPool,
    required Random random,
    int optionCount = 4,
  }) {
    final wanted = optionCount - 1;
    final candidates = <Country>[];

    final preferred = distractorPool.where((c) => c != answer).toList()
      ..shuffle(random);
    candidates.addAll(preferred.take(wanted));

    if (candidates.length < wanted) {
      final filler =
          fallbackPool
              .where((c) => c != answer && !candidates.contains(c))
              .toList()
            ..shuffle(random);
      candidates.addAll(filler.take(wanted - candidates.length));
    }

    final options = <Country>[answer, ...candidates]..shuffle(random);

    return QuizQuestion(answer: answer, options: options);
  }

  /// The country whose flag is shown and which one option must match.
  final Country answer;

  /// The shuffled answer choices, always containing [answer] exactly once.
  final List<Country> options;

  @override
  List<Object?> get props => [answer, options];
}
