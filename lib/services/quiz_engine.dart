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

  /// Base points awarded for a correct answer in timed mode.
  static const int timedCorrectPoints = 3;

  /// Points deducted for a single wrong answer.
  static const int wrongAnswerPenalty = 1;

  /// Additional penalty for answering wrong on a timed-mode question (timeout or wrong).
  static const int timedWrongPenalty = 2;

  /// Calculates points earned for a correct answer in normal mode.
  static int normalScoreIncrement() => normalCorrectPoints;

  /// Calculates points earned for a correct answer in timed mode.
  /// Streak bonus is additive: 1st = +3, 2nd = +4, 3rd = +5, etc.
  static int timedScoreIncrement(int consecutiveCorrect) {
    return timedCorrectPoints + (consecutiveCorrect - 1);
  }

  /// Returns the streak bonus text for display, or null if no bonus.
  static String? streakMultiplierText(int consecutiveCorrect) {
    if (consecutiveCorrect < 2) return null;
    final bonus = consecutiveCorrect - 1;
    return '+$bonus streak';
  }

  // ─── Penalties ────────────────────────────────────────────────────────────

  /// Calculates total penalty for an incorrect answer.
  /// [consecutiveIncorrect] is the count of consecutive wrongs *including* this one.
  /// Consecutive penalties compound: 1st wrong = -1, 2nd = -2, 3rd = -3, etc.
  /// Timed mode doubles the base penalty.
  static int incorrectPenalty(
    int consecutiveIncorrect, {
    bool isTimed = false,
  }) {
    final base = consecutiveIncorrect; // 1st = 1, 2nd = 2, 3rd = 3...
    return isTimed ? base * timedWrongPenalty : base * wrongAnswerPenalty;
  }

  /// Calculates penalty for a timeout in timed mode.
  static int timeoutPenalty(int consecutiveIncorrect) {
    return incorrectPenalty(consecutiveIncorrect, isTimed: true);
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
