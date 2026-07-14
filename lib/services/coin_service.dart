/// Pure logic for calculating Quiz Coin earnings.
/// Coins are a secondary currency awarded per correct answer in a session,
/// stored in Firestore alongside XP/badges/streaks.
class CoinService {
  CoinService._();

  /// Maximum coins a single quiz session can award.
  static const int maxCoinsPerSession = 50;

  /// Base coins awarded for a single correct answer.
  static const int baseCoinsPerCorrect = 1;

  /// Bonus coin added per consecutive correct answer beyond the first.
  /// e.g. 1st correct = +0, 2nd consecutive = +1, 3rd = +2, etc.
  static const int streakBonusPerConsecutive = 1;

  /// Multiplier applied to all coin earnings in timed mode.
  static const int timedModeMultiplier = 2;

  /// Calculates coins earned for a single correct answer.
  ///
  /// [consecutiveCorrect] is the count of consecutive correct answers
  /// *including* this one (1-based).
  /// [isTimed] doubles the earnings in timed mode.
  static int coinsForCorrectAnswer(int consecutiveCorrect, bool isTimed) {
    final streakBonus = (consecutiveCorrect - 1) * streakBonusPerConsecutive;
    final base = baseCoinsPerCorrect + streakBonus;
    return isTimed ? base * timedModeMultiplier : base;
  }

  /// Calculates total coins earned for the entire session.
  ///
  /// Loops through each correct answer and applies the streak formula,
  /// then caps the result at [maxCoinsPerSession].
  ///
  /// [totalCorrect] is the number of correct answers in the session.
  /// [isTimed] applies the timed mode multiplier.
  ///
  /// NOTE: This assumes the correct answers were answered consecutively
  /// for maximum streak. If you tracked individual answer streaks, pass
  /// the actual [consecutiveCorrectValues] list instead.
  static int totalCoinsForSession(int totalCorrect, bool isTimed) {
    int total = 0;
    // Simulate the streak: assume correct answers 1..totalCorrect
    // with each being consecutive (no breaks). This gives the maximum
    // possible coin earnings from this many correct answers.
    for (int i = 1; i <= totalCorrect; i++) {
      total += coinsForCorrectAnswer(i, isTimed);
    }
    return total.clamp(0, maxCoinsPerSession);
  }

  /// Calculates total coins for a session with actual streak tracking.
  ///
  /// [streakSegments] is a list of consecutive correct streaks lengths
  /// that occurred in the session. For example, if the player got
  /// 3 correct, then 1 wrong, then 4 correct, pass [3, 4].
  /// [isTimed] applies the timed mode multiplier.
  static int totalCoinsWithBreaks(List<int> streakSegments, bool isTimed) {
    int total = 0;
    for (final streakLength in streakSegments) {
      for (int i = 1; i <= streakLength; i++) {
        total += coinsForCorrectAnswer(i, isTimed);
      }
    }
    return total.clamp(0, maxCoinsPerSession);
  }
}
