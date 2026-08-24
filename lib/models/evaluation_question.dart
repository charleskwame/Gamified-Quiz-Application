/// A single evaluation question with its rating scale labels.
class EvaluationQuestion {
  final String category;
  final int number;
  final String question;
  final String minLabel;
  final String maxLabel;

  const EvaluationQuestion({
    required this.category,
    required this.number,
    required this.question,
    required this.minLabel,
    required this.maxLabel,
  });
}

/// The 20 evaluation questions used by the app, covering the major aspects
/// of the application on a 1–5 rating scale.
const List<EvaluationQuestion> evaluationQuestions = [
  // ── 1. Overall Experience ──
  EvaluationQuestion(
    category: 'Overall Experience',
    number: 1,
    question:
        'How satisfied are you with the overall quiz application experience?',
    minLabel: 'Very dissatisfied',
    maxLabel: 'Very satisfied',
  ),
  EvaluationQuestion(
    category: 'Overall Experience',
    number: 2,
    question:
        'How likely are you to recommend this app to a friend or colleague?',
    minLabel: 'Very unlikely',
    maxLabel: 'Very likely',
  ),
  EvaluationQuestion(
    category: 'Overall Experience',
    number: 3,
    question: 'How would you rate the visual design and quality of the app?',
    minLabel: 'Poor',
    maxLabel: 'Excellent',
  ),
  EvaluationQuestion(
    category: 'Overall Experience',
    number: 4,
    question: 'How easy is navigation around the app?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),
  EvaluationQuestion(
    category: 'Overall Experience',
    number: 5,
    question: 'How easy is it to start your first quiz?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),

  // ── 2. Performance & Stability ──
  EvaluationQuestion(
    category: 'Performance & Stability',
    number: 6,
    question:
        'How fast does the app start and how quickly do questions load?',
    minLabel: 'Very slow',
    maxLabel: 'Very fast',
  ),
  EvaluationQuestion(
    category: 'Performance & Stability',
    number: 7,
    question: 'How smooth do the screens and animations feel?',
    minLabel: 'Very janky',
    maxLabel: 'Very smooth',
  ),
  EvaluationQuestion(
    category: 'Performance & Stability',
    number: 8,
    question: 'How stable is the app (crashes, freezes, or hangs)?',
    minLabel: 'Very unstable',
    maxLabel: 'Very stable',
  ),

  // ── 3. Engagement ──
  EvaluationQuestion(
    category: 'Engagement',
    number: 9,
    question: 'How motivating is the app to keep you playing?',
    minLabel: 'Not motivating',
    maxLabel: 'Very motivating',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 10,
    question: 'How much do you enjoy a typical quiz session?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 11,
    question: 'How invested do you feel in your profile and progress?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 12,
    question: 'How often do you feel like coming back for another quiz session?',
    minLabel: 'Almost never',
    maxLabel: 'Very often',
  ),

  // ── 4. Features & Gamification ──
  EvaluationQuestion(
    category: 'Features & Gamification',
    number: 13,
    question: "How complete is the app's set of features?",
    minLabel: 'Very incomplete',
    maxLabel: 'Very complete',
  ),
  EvaluationQuestion(
    category: 'Features & Gamification',
    number: 14,
    question: 'How useful is the AI assistant or chat helper?',
    minLabel: 'Not useful',
    maxLabel: 'Very useful',
  ),
  EvaluationQuestion(
    category: 'Features & Gamification',
    number: 15,
    question: 'How motivating is the points or experience system?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Features & Gamification',
    number: 16,
    question: 'How fun are the badges / achievements that you can earn?',
    minLabel: 'Not fun',
    maxLabel: 'Very fun',
  ),

  // ── 5. Quiz Sessions & Learning ──
  EvaluationQuestion(
    category: 'Quiz Sessions & Learning',
    number: 17,
    question: 'How would you rate the quality of the quiz questions?',
    minLabel: 'Very poor',
    maxLabel: 'Excellent',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions & Learning',
    number: 18,
    question: 'How well balanced is the difficulty of the quiz questions?',
    minLabel: 'Poorly',
    maxLabel: 'Very well',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions & Learning',
    number: 19,
    question: 'How helpful is the feedback you get after answering?',
    minLabel: 'Not helpful',
    maxLabel: 'Very helpful',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions & Learning',
    number: 20,
    question: 'How good is the mix of fun and learning in the app?',
    minLabel: 'Very bad',
    maxLabel: 'Very good',
  ),
];