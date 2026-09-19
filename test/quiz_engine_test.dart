import 'package:flutter_test/flutter_test.dart';
import 'package:gamified_quiz_app/services/quiz_engine.dart';

void main() {
  group('QuizEngine scoring — normal mode', () {
    test('awards exactly +2 per correct answer', () {
      expect(QuizEngine.normalCorrectPoints, 2);
      expect(QuizEngine.normalScoreIncrement(), 2);
    });

    test('never penalises a wrong answer', () {
      expect(QuizEngine.normalWrongPenalty, 0);
      expect(QuizEngine.incorrectPenalty(1), 0);
      expect(QuizEngine.incorrectPenalty(5, isTimed: false), 0);
    });
  });

  group('QuizEngine scoring — challenge (timed) mode', () {
    test('awards a flat +5 with no streak bonus', () {
      expect(QuizEngine.timedCorrectPoints, 5);
      expect(QuizEngine.timedScoreIncrement(1), 5);
      expect(QuizEngine.timedScoreIncrement(2), 5);
      expect(QuizEngine.timedScoreIncrement(10), 5);
    });

    test('deducts a flat -2 that does not compound', () {
      expect(QuizEngine.timedWrongPenalty, 2);
      expect(QuizEngine.incorrectPenalty(1, isTimed: true), 2);
      expect(QuizEngine.incorrectPenalty(2, isTimed: true), 2);
      expect(QuizEngine.incorrectPenalty(7, isTimed: true), 2);
    });

    test('times out with the same flat -2 penalty', () {
      expect(QuizEngine.timeoutPenalty(1), 2);
      expect(QuizEngine.timeoutPenalty(3), 2);
    });

    test('allows 20 seconds per question', () {
      expect(QuizEngine.timedQuestionSeconds, 20);
    });
  });
}