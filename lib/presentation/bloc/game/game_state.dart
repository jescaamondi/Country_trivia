import 'package:country_trivia/domain/entities/attempt_scoring.dart';
import 'package:country_trivia/domain/entities/quiz_question.dart';
import 'package:equatable/equatable.dart';

/// Lifecycle of a single run.
enum GameStatus {
  /// Nothing has happened yet.
  initial,

  /// The country pool is being fetched.
  loading,

  /// A flag is on screen and the player may answer.
  playing,

  /// The round is resolved: the answer is revealed and feedback is showing.
  answered,

  /// Every country in the pool has been played.
  completed,

  /// The country pool could not be loaded.
  failure,
}

/// Immutable snapshot of everything the quiz screen renders.
class GameState extends Equatable {
  const GameState({
    this.status = GameStatus.initial,
    this.question,
    this.solvedCount = 0,
    this.correctAnswers = 0,
    this.totalCountries = 0,
    this.score = 0,
    this.attemptsUsed = 0,
    this.wrongOptions = const {},
    this.answeredCorrectly,
    this.pointsEarned = 0,
    this.errorMessage,
  });

  final GameStatus status;
  final QuizQuestion? question;

  /// Countries whose flag has been played, whether or not the player got it
  /// right. Drives the `15 / 195` progress readout and the end of the run.
  final int solvedCount;

  /// How many of those were actually answered correctly.
  final int correctAnswers;

  /// Size of the pool the run was started with.
  final int totalCountries;

  final int score;

  /// Attempts consumed on the current flag (0 when a round starts).
  final int attemptsUsed;

  /// ISO codes of options already guessed incorrectly this round. They stay
  /// disabled for the rest of the round.
  final Set<String> wrongOptions;

  /// `true` when the round ended on a correct guess, `false` when the player
  /// ran out of attempts, `null` while the round is still open.
  final bool? answeredCorrectly;

  /// Points banked by the round that just finished.
  final int pointsEarned;

  final String? errorMessage;

  /// Sentinel telling [copyWith] that an argument was not supplied, so a
  /// nullable field can still be explicitly reset back to `null`.
  static const Object _unset = Object();

  /// Attempts still available for the current flag.
  int get attemptsRemaining {
    final left = AttemptScoring.maxAttempts - attemptsUsed;
    return left < 0 ? 0 : left;
  }

  /// Whether the player may still tap an option.
  bool get canAnswer => status == GameStatus.playing && question != null;

  /// Whether the "next flag" button should be shown.
  bool get canAdvance => status == GameStatus.answered;

  /// Whether the player just solved the flag.
  bool get isCorrect => answeredCorrectly == true;

  /// Points still on the table for the current flag.
  int get pointsOnTheLine => AttemptScoring.pointsForAttempt(attemptsUsed + 1);

  /// Best possible score for this run, used for the progress percentage.
  int get maxScore => totalCountries * AttemptScoring.pointsPerAttempt.first;

  /// Run completion as a 0..1 fraction, for the progress bar.
  double get progress => totalCountries == 0 ? 0 : solvedCount / totalCountries;

  GameState copyWith({
    GameStatus? status,
    Object? question = _unset,
    int? solvedCount,
    int? correctAnswers,
    int? totalCountries,
    int? score,
    int? attemptsUsed,
    Set<String>? wrongOptions,
    Object? answeredCorrectly = _unset,
    int? pointsEarned,
    Object? errorMessage = _unset,
  }) {
    return GameState(
      status: status ?? this.status,
      question: identical(question, _unset)
          ? this.question
          : question as QuizQuestion?,
      solvedCount: solvedCount ?? this.solvedCount,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalCountries: totalCountries ?? this.totalCountries,
      score: score ?? this.score,
      attemptsUsed: attemptsUsed ?? this.attemptsUsed,
      wrongOptions: wrongOptions ?? this.wrongOptions,
      answeredCorrectly: identical(answeredCorrectly, _unset)
          ? this.answeredCorrectly
          : answeredCorrectly as bool?,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    question,
    solvedCount,
    correctAnswers,
    totalCountries,
    score,
    attemptsUsed,
    wrongOptions,
    answeredCorrectly,
    pointsEarned,
    errorMessage,
  ];
}
