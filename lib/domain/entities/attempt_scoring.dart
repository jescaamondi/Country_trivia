/// The attempt based scoring rules for the quiz.
///
/// 1st try 10 points, 2nd try 8 points, 3rd try 5 points. Running out of
/// attempts scores 0.
class AttemptScoring {
  const AttemptScoring._();

  /// Attempts allowed per flag.
  static const int maxAttempts = 3;

  /// Points for attempt 1, 2 and 3 respectively.
  static const List<int> pointsPerAttempt = [10, 8, 5];

  /// Points awarded for answering correctly on [attempt] (1 indexed).
  static int pointsForAttempt(int attempt) {
    if (attempt < 1 || attempt > maxAttempts) return 0;
    return pointsPerAttempt[attempt - 1];
  }
}
