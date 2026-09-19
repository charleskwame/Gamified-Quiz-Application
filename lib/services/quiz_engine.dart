import 'dart:math';

/// Pure business logic for quiz scoring and shuffling.
/// No Flutter or state dependencies.
class QuizEngine {
  /// Fisher-Yates Shuffle Algorithm to ensure uniform random distribution.
  static void fisherYatesShuffle<T>(List<T> list) {
    final random = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

  /// Returns whether the selected option is correct for the given correct answer.
  static bool isOptionCorrect(String option, String correctAnswer) {
    return option.trim().toLowerCase().startsWith(correctAnswer.toLowerCase());
  }

  // ─── Scoring ─────────────────────────────────────────────────────────────

  /// Base points awarded for a correct answer in normal mode.
  static const int normalCorrectPoints = 2;

  /// Base points awarded for a correct answer in timed (challenge) mode.
  static const int timedCorrectPoints = 5;

  /// Seconds allowed per question in timed (challenge) mode.
  static const int timedQuestionSeconds = 20;

  /// Points deducted for a wrong answer in normal mode.
  /// Normal mode is penalty-free, so this is always zero.
  static const int normalWrongPenalty = 0;

  /// Flat points deducted for a wrong answer or timeout in timed mode.
  /// The penalty no longer compounds on consecutive incorrect answers.
  static const int timedWrongPenalty = 2;

  /// Calculates points earned for a correct answer in normal mode.
  static int normalScoreIncrement() => normalCorrectPoints;

  /// Calculates points earned for a correct answer in timed mode.
  /// Flat award — no streak bonus is applied.
  static int timedScoreIncrement(int consecutiveCorrect) {
    return timedCorrectPoints;
  }

  /// Returns the streak bonus text for display, or null if no bonus.
  static String? streakMultiplierText(int consecutiveCorrect) {
    if (consecutiveCorrect < 2) return null;
    final bonus = consecutiveCorrect - 1;
    return '+$bonus streak';
  }

  // ─── Penalties ────────────────────────────────────────────────────────────

  /// Calculates total penalty for an incorrect answer.
  /// - Normal mode is penalty-free: always returns 0.
  /// - Timed (challenge) mode applies a flat [timedWrongPenalty] (-2) that does
  ///   not compound on consecutive wrong answers. [consecutiveIncorrect] is kept
  ///   for call-site compatibility and no longer affects the amount.
  static int incorrectPenalty(
    int consecutiveIncorrect, {
    bool isTimed = false,
  }) {
    return isTimed ? timedWrongPenalty : normalWrongPenalty;
  }

  /// Calculates penalty for a timeout in timed mode. Flat [timedWrongPenalty].
  static int timeoutPenalty(int consecutiveIncorrect) {
    return timedWrongPenalty;
  }

  // ─── Session XP Cap ───────────────────────────────────────────────────────

  /// Returns the maximum XP a single session can award.
  /// Capped at 30% of the XP needed to reach the next level from the current score.
  static int sessionXpCap(int currentTotalScore) {
    // Import LevelSystem lazily to avoid circular dependency
    final levelSystem = _getXpToNextLevel(currentTotalScore);
    final xpNeeded = levelSystem;
    if (xpNeeded <= 0) return 100; // Max level fallback cap
    return (xpNeeded * 0.3).ceil();
  }

  static int _getXpToNextLevel(int score) {
    // Inline approach: we reference LevelSystem here since engine uses it
    // but we avoid import by importing at file level
    return _xpToNextLevelForScore(score);
  }

  /// Helper — computes XP needed for next level (mirrors LevelSystem logic).
  static int _xpToNextLevelForScore(int score) {
    // We define level thresholds inline to avoid the import
    const thresholds = [
      0,
      250,
      600,
      1200,
      2000,
      3000,
      4500,
      6500,
      9000,
      12000,
      16000,
      21000,
      27000,
      34000,
      44000,
    ];
    int current = 0;
    for (final t in thresholds) {
      if (score >= t) {
        current = t;
      } else {
        return t - current;
      }
    }
    return 0; // max level
  }
}
