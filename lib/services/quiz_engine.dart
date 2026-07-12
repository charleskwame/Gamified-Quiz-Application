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

  /// Returns the streak multiplier text for a given consecutive-correct count.
  /// Returns null if below multiplier threshold (consecutive < 2).
  static String? streakMultiplierText(int consecutiveCorrect) {
    if (consecutiveCorrect < 2) return null;
    final double bonusMultiplier = (consecutiveCorrect - 1) * 0.5;
    final double totalMultiplier = 1.0 + bonusMultiplier;
    return totalMultiplier.toStringAsFixed(1);
  }

  /// Calculates the score increment for a correct answer in timed mode.
  /// Bonus multiplier: 2nd correct = +0.5, 3rd = +1.0, 4th = +1.5, etc.
  static int timedScoreIncrement(int consecutiveCorrect) {
    final double bonusMultiplier = (consecutiveCorrect - 1) * 0.5;
    final double totalMultiplier = 1.0 + bonusMultiplier;
    return (10 * totalMultiplier).round();
  }
}
