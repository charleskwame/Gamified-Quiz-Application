import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/quiz_engine.dart';
import '../services/quote_service.dart';
import '../services/notification_service.dart';
import '../widgets/quiz/quiz_loading_view.dart';
import '../widgets/quiz/quiz_error_view.dart';
import '../widgets/quiz/quiz_results_view.dart';
import '../widgets/quiz/quiz_badge_celebration.dart';
import '../widgets/quiz/quiz_ai_chat_sheet.dart';
import '../widgets/quiz/quiz_streak_badge.dart';
import '../widgets/quiz/quiz_ai_fab.dart';

class QuizPlayScreen extends StatefulWidget {
  final String category;
  final bool isTimed;
  final bool isOffline;

  const QuizPlayScreen({
    super.key,
    required this.category,
    required this.isTimed,
    required this.isOffline,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with TickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();

  // ─── State ─────────────────────────────────────────────────────────────────

  int _consecutiveIncorrect = 0;
  int _consecutiveCorrect = 0;
  AnimationController? _aiButtonAnimationController;
  AnimationController? _progressAnimationController;
  AnimationController? _flameAnimationController;
  final List<Question> _incorrectQuestions = [];

  List<Question> _questions = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _currentIndex = 0;
  List<String> _newlyUnlockedBadges = [];
  int _score = 0;
  int _correctAnswers = 0;
  String? _selectedOption;
  bool _isAnswered = false;

  // Timer fields
  Timer? _timer;
  int _timeLeft = 15;

  // Random quote for completion screen
  String? _randomQuoteText;
  String? _randomQuoteAuthor;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
    _aiButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _flameAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimationController?.dispose();
    _aiButtonAnimationController?.dispose();
    _flameAnimationController?.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadQuizQuestions() async {
    try {
      List<Question> loadedQuestions;
      if (widget.isOffline) {
        loadedQuestions = await _db.loadOfflineQuestions(widget.category);
      } else {
        loadedQuestions = await _db.getQuestionsByCategory(widget.category);
      }

      if (loadedQuestions.isEmpty) {
        throw Exception('No questions available.');
      }

      QuizEngine.fisherYatesShuffle(loadedQuestions);
      _questions = loadedQuestions.take(10).toList();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (widget.isTimed) {
        _startTimer();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _progressAnimationController?.dispose();
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _progressAnimationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimeOut();
      }
    });

    _progressAnimationController!.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _timeLeft =
            (_progressAnimationController!.duration!.inSeconds *
                    (1.0 - _progressAnimationController!.value))
                .round()
                .clamp(0, 15);
      });
    });
  }

  void _handleTimeOut() {
    final currentQuestion = _questions[_currentIndex];
    setState(() {
      _isAnswered = true;
      _selectedOption = '';
      _consecutiveIncorrect++;
      _consecutiveCorrect = 0;
      _incorrectQuestions.add(currentQuestion);
    });
  }

  // ─── Answer Selection ──────────────────────────────────────────────────────

  void _selectAnswer(String option) {
    if (_isAnswered) return;
    _timer?.cancel();
    _progressAnimationController?.stop();

    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect = QuizEngine.isOptionCorrect(
      option,
      currentQuestion.correctAnswer,
    );

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      if (isCorrect) {
        _correctAnswers++;
        _consecutiveCorrect++;
        _consecutiveIncorrect = 0;

        if (widget.isTimed) {
          _score += QuizEngine.timedScoreIncrement(_consecutiveCorrect);
        } else {
          _score += 1;
        }
      } else {
        _consecutiveCorrect = 0;
        _consecutiveIncorrect++;
        _incorrectQuestions.add(currentQuestion);
      }
    });
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
      });
      if (widget.isTimed) {
        _startTimer();
      }
    } else {
      _finishQuiz();
    }
  }

  // ─── Quiz Completion ───────────────────────────────────────────────────────

  Future<void> _finishQuiz() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    List<String> unlocked = [];
    if (user != null && !widget.isOffline) {
      try {
        unlocked = await _db.processQuizCompletion(
          uid: user.uid,
          category: widget.category,
          scoreIncrement: _score,
          correctIncrement: _correctAnswers,
          answeredIncrement: _questions.length,
          isTimed: widget.isTimed,
        );
      } catch (e) {
        // Silently catch network failures or write problems in offline context
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;
      if (notificationsEnabled) {
        await NotificationService().rescheduleForTomorrow();
      }
    } catch (e) {
      // Ignore notification scheduling errors
    }

    // Load a random motivational quote
    final quote = await QuoteService.loadRandomQuote();
    _randomQuoteText = quote?.$1;
    _randomQuoteAuthor = quote?.$2;

    if (mounted) {
      setState(() {
        _isLoading = false;
        _newlyUnlockedBadges = unlocked;
        _currentIndex = _questions.length; // Triggers completion state
      });

      if (unlocked.isNotEmpty) {
        showBadgeCelebrationDialog(context, unlocked);
        for (int i = 0; i < unlocked.length; i++) {
          Future.delayed(Duration(seconds: i * 4), () {
            if (mounted) {
              showBadgeTopToast(context, unlocked[i]);
            }
          });
        }
      }
    }
  }

  // ─── AI Chat ───────────────────────────────────────────────────────────────

  void _showAiChatInterface() {
    QuizAiChatSheet.show(
      context,
      category: widget.category,
      incorrectQuestions: _incorrectQuestions,
    );
  }

  // ─── Quit Confirmation ─────────────────────────────────────────────────────

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Challenge?'),
        content: const Text(
          'Are you sure you want to quit? Your progress for this challenge will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_isLoading) {
      return const QuizLoadingView();
    }

    // Error state
    if (_errorMessage != null) {
      return QuizErrorView(
        errorMessage: _errorMessage!,
        onGoBack: () => Navigator.pop(context),
      );
    }

    // Results screen
    if (_currentIndex >= _questions.length) {
      return QuizResultsView(
        score: _score,
        correctAnswers: _correctAnswers,
        totalQuestions: _questions.length,
        isOffline: widget.isOffline,
        newlyUnlockedBadges: _newlyUnlockedBadges,
        quoteText: _randomQuoteText,
        quoteAuthor: _randomQuoteAuthor,
        onBack: () => Navigator.pop(context),
      );
    }

    // ─── Quiz Question View ──────────────────────────────────────────────────
    final question = _questions[_currentIndex];
    final bool showStreakBadge = widget.isTimed && _consecutiveCorrect >= 2;

    return Scaffold(
      floatingActionButton:
          (!widget.isTimed &&
              !widget.isOffline &&
              _consecutiveIncorrect >= 2 &&
              _currentIndex < _questions.length)
          ? QuizAiFab(
              animationController: _aiButtonAnimationController!,
              onPressed: _showAiChatInterface,
            )
          : null,
      appBar: AppBar(
        title: Text(
          widget.category,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _showQuitDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                10,
                24,
                showStreakBadge ? 176 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer Progress bar (if Timed Mode)
                  if (widget.isTimed) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _progressAnimationController!,
                        builder: (context, child) {
                          final double progress =
                              1.0 - _progressAnimationController!.value;
                          return LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: _timeLeft <= 4
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
                            backgroundColor: const Color(0xFFE6EAF2),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Question Card
                  _buildQuestionCard(question),

                  const SizedBox(height: 24),

                  // Option Buttons
                  ...question.options.map(
                    (option) =>
                        _buildOptionTile(option, question.correctAnswer),
                  ),

                  // Explanation & Next Button
                  if (_isAnswered) ...[
                    const SizedBox(height: 16),
                    _buildExplanationBox(question),
                    const SizedBox(height: 24),
                    _buildNextButton(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          // Streak multiplier badge
          if (showStreakBadge)
            Positioned(
              right: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
              child: IgnorePointer(
                child: QuizStreakBadge(
                  animationController: _flameAnimationController!,
                  consecutiveCorrect: _consecutiveCorrect,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Widget Helpers (lightweight, contained within this file) ──────────────

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05121826),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (widget.isTimed)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _timeLeft <= 4
                        ? Colors.red.shade50
                        : const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 14,
                        color: _timeLeft <= 4
                            ? Colors.red
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_timeLeft}s',
                        style: TextStyle(
                          color: _timeLeft <= 4
                              ? Colors.red
                              : const Color(0xFF121826),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF121826),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String option, String correctAnswer) {
    final isSelected = _selectedOption == option;
    final isCorrectOption = QuizEngine.isOptionCorrect(option, correctAnswer);

    Color borderC = const Color(0xFFE6EAF2);
    Color bgC = Colors.white;
    IconData? stateIcon;

    if (_isAnswered) {
      if (isCorrectOption) {
        borderC = const Color(0xFF4CAF50);
        bgC = const Color(0xFFE8F5E9);
        stateIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        borderC = const Color(0xFFF44336);
        bgC = const Color(0xFFFFEBEE);
        stateIcon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      borderC = Theme.of(context).colorScheme.primary;
      bgC = Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: bgC,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderC, width: 2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isAnswered ? null : () => _selectAnswer(option),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected || (_isAnswered && isCorrectOption)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: const Color(0xFF121826),
                      ),
                    ),
                  ),
                  if (stateIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      stateIcon,
                      color: stateIcon == Icons.check_circle_rounded
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationBox(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explanation',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4B5565),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question.explanation.isEmpty || question.explanation == 'None.'
                ? 'The correct answer is indeed option (${question.correctAnswer.toUpperCase()}).'
                : question.explanation,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4B5565),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _nextQuestion,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text(
          _currentIndex < _questions.length - 1
              ? 'Next Question'
              : 'Finish Challenge',
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
