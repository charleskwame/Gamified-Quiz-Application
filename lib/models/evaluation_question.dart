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

/// All 48 evaluation questions from `evaluation_questions.md`,
/// organized by category. Each question is rated on a 1–5 scale.
const List<EvaluationQuestion> evaluationQuestions = [
  // ── 1. General / Overall Experience ──
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 1,
    question: 'How satisfied are you with the overall quiz application experience?',
    minLabel: 'Very dissatisfied',
    maxLabel: 'Very satisfied',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 2,
    question: 'How likely are you to recommend this app to a friend or colleague?',
    minLabel: 'Very unlikely',
    maxLabel: 'Very likely',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 3,
    question: 'How would you rate the visual design and quality of the app?',
    minLabel: 'Poor',
    maxLabel: 'Excellent',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 4,
    question: 'How likely are you to come back and use the app again?',
    minLabel: 'Very unlikely',
    maxLabel: 'Very likely',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 5,
    question: 'How well does the app meet your expectations?',
    minLabel: 'Not at all',
    maxLabel: 'Very well',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 6,
    question: 'How easy is navigation around the app?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 7,
    question: 'How easy is it to understand the icons and labels?',
    minLabel: 'Very confusing',
    maxLabel: 'Very clear',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 8,
    question: 'How easy is it to start your first quiz?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 9,
    question: 'How easy is it to understand the question text and answer options?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),
  EvaluationQuestion(
    category: 'General / Overall Experience',
    number: 10,
    question: 'How easy is it to view past results and history?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),

  // ── 2. Usability ──
  EvaluationQuestion(
    category: 'Usability',
    number: 11,
    question: 'How accessible is the app for users with different abilities?',
    minLabel: 'Very poor',
    maxLabel: 'Very good',
  ),
  EvaluationQuestion(
    category: 'Usability',
    number: 12,
    question: 'How helpful is the onboarding or tutorial when you first use the app?',
    minLabel: 'Not helpful',
    maxLabel: 'Very helpful',
  ),
  EvaluationQuestion(
    category: 'Usability',
    number: 13,
    question: 'How consistent and clear is the layout across screens?',
    minLabel: 'Very confusing',
    maxLabel: 'Very clear',
  ),
  EvaluationQuestion(
    category: 'Usability',
    number: 14,
    question: 'How obvious is it what to tap or do next on each screen?',
    minLabel: 'Confusing',
    maxLabel: 'Always clear',
  ),

  // ── 3. Performance ──
  EvaluationQuestion(
    category: 'Performance',
    number: 15,
    question: 'How fast does the app start up?',
    minLabel: 'Very slow',
    maxLabel: 'Very fast',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 16,
    question: 'How smooth do the screens and animations feel?',
    minLabel: 'Very janky',
    maxLabel: 'Very smooth',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 17,
    question: 'How quickly do questions load when a quiz starts?',
    minLabel: 'Very slow',
    maxLabel: 'Very fast',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 18,
    question: 'How stable is the app (crashes, freezes, or hangs)?',
    minLabel: 'Very unstable',
    maxLabel: 'Very stable',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 19,
    question: 'How responsive is the app to taps?',
    minLabel: 'Very laggy',
    maxLabel: 'Very responsive',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 20,
    question: 'How well does the app handle weak or steady internet connections?',
    minLabel: 'Very poorly',
    maxLabel: 'Very well',
  ),
  EvaluationQuestion(
    category: 'Performance',
    number: 21,
    question: 'How easy is it to tell the state of loading or saving?',
    minLabel: 'Very confusing',
    maxLabel: 'Very clear',
  ),

  // ── 4. Engagement ──
  EvaluationQuestion(
    category: 'Engagement',
    number: 22,
    question: 'How motivating is the app to keep you playing?',
    minLabel: 'Not motivating',
    maxLabel: 'Very motivating',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 23,
    question: 'How often do you feel like coming back for another quiz session?',
    minLabel: 'Almost never',
    maxLabel: 'Very often',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 24,
    question: 'How much do you enjoy a typical quiz session?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 25,
    question: 'How often do you play several quizzes one after the other?',
    minLabel: 'Rarely',
    maxLabel: 'Very often',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 26,
    question: 'How invested do you feel in your profile and progress?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Engagement',
    number: 27,
    question: 'How satisfying is the feeling of finishing a quiz?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),

  // ── 5. Features ──
  EvaluationQuestion(
    category: 'Features',
    number: 28,
    question: "How complete is the app's set of features?",
    minLabel: 'Very incomplete',
    maxLabel: 'Very complete',
  ),
  EvaluationQuestion(
    category: 'Features',
    number: 29,
    question: 'How useful are the features you have tried?',
    minLabel: 'Not useful',
    maxLabel: 'Very useful',
  ),
  EvaluationQuestion(
    category: 'Features',
    number: 30,
    question: 'How easy is it to discover the features?',
    minLabel: 'Very hard',
    maxLabel: 'Very easy',
  ),
  EvaluationQuestion(
    category: 'Features',
    number: 31,
    question: 'How useful is the AI assistant or chat helper?',
    minLabel: 'Not useful',
    maxLabel: 'Very useful',
  ),
  EvaluationQuestion(
    category: 'Features',
    number: 32,
    question: 'How useful is the feedback and explanation you get after answering?',
    minLabel: 'Not useful',
    maxLabel: 'Very useful',
  ),
  EvaluationQuestion(
    category: 'Features',
    number: 33,
    question: 'How much control do you get over quiz options, such as topic or difficulty?',
    minLabel: 'Very little',
    maxLabel: 'Great deal',
  ),

  // ── 6. Quiz Sessions ──
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 34,
    question: 'How would you rate the quality of the quiz questions?',
    minLabel: 'Very poor',
    maxLabel: 'Excellent',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 35,
    question: 'How well balanced is the difficulty of the quiz questions?',
    minLabel: 'Poorly',
    maxLabel: 'Very well',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 36,
    question: 'How varied are the topics and questions between sessions?',
    minLabel: 'Very limited',
    maxLabel: 'Very varied',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 37,
    question: 'How fair is the quiz timer?',
    minLabel: 'Very unfair',
    maxLabel: 'Very fair',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 38,
    question: 'How helpful is the message you see after each answer?',
    minLabel: 'Not helpful',
    maxLabel: 'Very helpful',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 39,
    question: 'How clear and complete is the results screen at the end?',
    minLabel: 'Confusing',
    maxLabel: 'Very clear',
  ),
  EvaluationQuestion(
    category: 'Quiz Sessions',
    number: 40,
    question: 'How well does the app show how far you are in a quiz?',
    minLabel: 'Confusing',
    maxLabel: 'Very clear',
  ),

  // ── 7. Gamified Elements ──
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 41,
    question: 'How motivating is the points or experience system?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 42,
    question: 'How satisfying is it when you level up?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 43,
    question: 'How fun are the badges / achievements that you can earn?',
    minLabel: 'Not fun',
    maxLabel: 'Very fun',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 44,
    question: 'How engaging are the competitions and leaderboard?',
    minLabel: 'Not engaging',
    maxLabel: 'Very engaging',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 45,
    question: 'How much do daily rewards or streaks encourage you to return?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 46,
    question: 'How satisfying are the rewards you receive?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 47,
    question: 'How much do sounds and animations make the game fun?',
    minLabel: 'Not at all',
    maxLabel: 'Very much',
  ),
  EvaluationQuestion(
    category: 'Gamified Elements',
    number: 48,
    question: 'How good is the mix of fun and learning in the app?',
    minLabel: 'Very bad',
    maxLabel: 'Very good',
  ),
];