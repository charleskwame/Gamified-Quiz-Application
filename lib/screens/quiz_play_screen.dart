import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import '../models/question.dart';
import '../services/database_service.dart';
import '../services/quiz_engine.dart';
import '../services/quote_service.dart';
import '../widgets/home/particle_background.dart';
import '../widgets/quiz/quiz_loading_view.dart';
import '../widgets/quiz/quiz_error_view.dart';
import '../widgets/quiz/quiz_results_view.dart';
import '../widgets/quiz/quiz_level_up_screen.dart';
import '../widgets/quiz/quiz_badge_celebration.dart';
import '../widgets/quiz/quiz_ai_chat_sheet.dart';
import '../widgets/quiz/quiz_streak_badge.dart';
import '../widgets/quiz/quiz_ai_fab.dart';
import '../widgets/quiz/quiz_game_option.dart';
import '../widgets/quiz/quiz_score_popup.dart';
import '../widgets/quiz/quiz_circular_timer.dart';

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
  AnimationController? _questionSlideController;
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

  // Score popup
  int _lastScoreIncrement = 0;
  bool _showScorePopup = false;

  // Confetti
  late ConfettiController _confettiController;

  // Track correct/incorrect per question for progress dots
  final List<bool> _answerResults = [];

  // Timer fields
  Timer? _timer;
  int _timeLeft = 15;

  // Random quote for completion screen
  String? _randomQuoteText;
  String? _randomQuoteAuthor;

  // Penalty tracking
  int _penaltyDeductions = 0;

  // Level-up tracking
  int _oldLevel = 1;
  int _oldTotalScore = 0;
  int _updatedTotalScore = 0;
  String _displayName = 'Scholar';
  String? _avatarUrl;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _aiButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _flameAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _questionSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimationController?.dispose();
    _aiButtonAnimationController?.dispose();
    _flameAnimationController?.dispose();
    _questionSlideController?.dispose();
    _confettiController.dispose();
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

    if (_progressAnimationController == null) {
      _progressAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      );
      _progressAnimationController!.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _handleTimeOut();
        }
      });
    } else {
      _progressAnimationController!.reset();
    }

    setState(() {
      _timeLeft = 15;
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
      _answerResults.add(false);

      // Apply penalty if 2+ consecutive incorrect
      if (_consecutiveIncorrect >= 2 && _score > 0) {
        _score -= 1;
        _penaltyDeductions++;
        _lastScoreIncrement = -1;
        _showScorePopup = true;
      } else {
        _showScorePopup = false;
      }
    });

    // Track this timed-out question as incorrect for lecturer insights
    if (!widget.isOffline) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _db.incrementIncorrectQuestion(
          category: widget.category,
          questionId: currentQuestion.id,
        );
      }
    }
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
        _answerResults.add(true);
        _correctAnswers++;
        _consecutiveCorrect++;
        _consecutiveIncorrect = 0;

        if (widget.isTimed) {
          _score += QuizEngine.timedScoreIncrement(_consecutiveCorrect);
          _lastScoreIncrement = QuizEngine.timedScoreIncrement(
            _consecutiveCorrect,
          );
        } else {
          _score += 5;
          _lastScoreIncrement = 5;
        }
        _showScorePopup = true;

        // Trigger confetti for correct answers
        _confettiController.play();
      } else {
        _answerResults.add(false);
        _consecutiveCorrect = 0;
        _consecutiveIncorrect++;
        _incorrectQuestions.add(currentQuestion);

        // Apply penalty if 2+ consecutive incorrect
        if (_consecutiveIncorrect >= 2 && _score > 0) {
          _score -= 1;
          _penaltyDeductions++;
          _lastScoreIncrement = -1;
          _showScorePopup = true;
        } else {
          _showScorePopup = false;
        }

        // Track this incorrect answer in Firestore for lecturer insights
        // (only for normal and timed modes, not offline)
        if (!widget.isOffline) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            _db.incrementIncorrectQuestion(
              category: widget.category,
              questionId: currentQuestion.id,
            );
          }
        }
      }
    });

    // Hide score popup after a delay
    if (isCorrect) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => _showScorePopup = false);
        }
      });
    }
  }

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _nextQuestion() {
    _confettiController.stop();
    if (_currentIndex < _questions.length - 1) {
      _questionSlideController?.forward(from: 0.0);
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _isAnswered = false;
        _showScorePopup = false;
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
    _confettiController.stop();
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    List<String> unlocked = [];
    int oldLevel = 1;
    int oldTotalScore = 0;
    int updatedTotalScore = 0;
    String displayName = 'Scholar';
    String? avatarUrl;

    if (user != null && !widget.isOffline) {
      try {
        // Read old score before processing
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        oldTotalScore = userData?['score'] ?? 0;
        oldLevel = (oldTotalScore ~/ 100) + 1;
        displayName = userData?['displayName'] ?? 'Scholar';
        avatarUrl = userData?['avatarUrl'] as String?;

        unlocked = await _db.processQuizCompletion(
          uid: user.uid,
          category: widget.category,
          scoreIncrement: _score,
          correctIncrement: _correctAnswers,
          answeredIncrement: _questions.length,
          isTimed: widget.isTimed,
        );

        // Compute updated total score locally: old total + net session score
        // (net session score already accounts for penalty deductions)
        updatedTotalScore = oldTotalScore + _score;

        // Record rank history entry after successful quiz completion
        // Calculate rank letter based on session performance percentage
        final totalQuestions = _questions.length;
        final percentage = totalQuestions > 0
            ? (_correctAnswers / totalQuestions) * 100
            : 0.0;
        final String rankLetter;
        if (percentage >= 90) {
          rankLetter = 'S';
        } else if (percentage >= 80) {
          rankLetter = 'A';
        } else if (percentage >= 70) {
          rankLetter = 'B';
        } else if (percentage >= 60) {
          rankLetter = 'C';
        } else if (percentage >= 50) {
          rankLetter = 'D';
        } else {
          rankLetter = 'E';
        }
        await _db.recordRankHistoryEntry(
          uid: user.uid,
          rank: rankLetter,
          category: widget.category,
          percentage: percentage,
        );
      } catch (e) {
        // Silently catch network failures or write problems in offline context
      }
    }

    // Load a random motivational quote
    final quote = await QuoteService.loadRandomQuote();
    _randomQuoteText = quote?.$1;
    _randomQuoteAuthor = quote?.$2;

    // Store level data for results screen
    _oldLevel = oldLevel;
    _oldTotalScore = oldTotalScore;
    _updatedTotalScore = updatedTotalScore;
    _displayName = displayName;
    _avatarUrl = avatarUrl;

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

      // Check for level-up after a short delay (after badge dialogs dismiss)
      final newLevel = (updatedTotalScore ~/ 100) + 1;
      if (newLevel > oldLevel) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => QuizLevelUpScreen(
                  data: LevelUpData(
                    oldLevel: oldLevel,
                    newLevel: newLevel,
                    totalScore: updatedTotalScore,
                    avatarUrl: avatarUrl,
                    displayName: displayName,
                  ),
                ),
              ),
            );
          }
        });
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
        backgroundColor: const Color(0xFF1E2246),
        title: const Text(
          'Quit Challenge?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to quit? Your progress for this challenge will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
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
        oldLevel: _oldLevel,
        oldTotalScore: _oldTotalScore,
        updatedTotalScore: _updatedTotalScore,
        avatarUrl: _avatarUrl,
        displayName: _displayName,
        penaltyDeductions: _penaltyDeductions,
      );
    }

    // ─── Quiz Question View ──────────────────────────────────────────────────
    final question = _questions[_currentIndex];
    final bool showStreakBadge = widget.isTimed && _consecutiveCorrect >= 2;

    return ParticleBackground(
      isActive: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: _showQuitDialog,
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  showStreakBadge ? 176 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Top bar: Progress + Timer ──────────────────────
                    Row(
                      children: [
                        // Question progress dots
                        Expanded(child: _buildProgressDots()),
                        if (widget.isTimed &&
                            _progressAnimationController != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: QuizCircularTimer(
                              animationController:
                                  _progressAnimationController!,
                              timeLeft: _timeLeft,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Question Card ──────────────────────────────────
                    _buildQuestionCard(question),
                    const SizedBox(height: 20),

                    // ─── Option Buttons ─────────────────────────────────
                    ...List.generate(question.options.length, (index) {
                      final option = question.options[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuizGameOption(
                          option: option,
                          correctAnswer: question.correctAnswer,
                          selectedOption: _selectedOption,
                          isAnswered: _isAnswered,
                          onTap: () => _selectAnswer(option),
                          index: index,
                        ),
                      );
                    }),

                    // ─── Explanation & Next Button ──────────────────────
                    if (_isAnswered) ...[
                      const SizedBox(height: 8),
                      _buildExplanationBox(question),
                      const SizedBox(height: 20),
                      _buildNextButton(),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),

            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 20,
                minBlastForce: 5,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.3,
                colors: const [
                  Color(0xFF4ADE80),
                  Color(0xFF6366F1),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                  Colors.white,
                ],
                shouldLoop: false,
              ),
            ),

            // Score popup - positioned near the question card
            if (_showScorePopup)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.38,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: QuizScorePopup(
                      points: _lastScoreIncrement,
                      isTimed: widget.isTimed,
                    ),
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
      ),
    );
  }

  // ─── Progress Dots ──────────────────────────────────────────────────────────

  Widget _buildProgressDots() {
    return Row(
      children: List.generate(_questions.length, (index) {
        final bool isCurrent = index == _currentIndex;
        final bool isPast = index < _currentIndex;

        final bool? answerResult = isPast && index < _answerResults.length
            ? _answerResults[index]
            : null;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isPast && answerResult != null
                    ? (answerResult
                          ? const Color(0xFF4ADE80) // green for correct
                          : const Color(0xFFEF4444)) // red for incorrect
                    : isCurrent
                    ? const Color(0xFF6366F1)
                    : const Color(0xFF3D4375),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Widget Helpers (lightweight, contained within this file) ──────────────

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2F5A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D4375)),
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 12,
                      color: Color(0xFF818CF8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'QUESTION ${_currentIndex + 1} OF ${_questions.length}',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
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
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationBox(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF252B55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D4375)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              const Text(
                'Explanation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            question.explanation.isEmpty || question.explanation == 'None.'
                ? 'The correct answer is indeed option (${question.correctAnswer.toUpperCase()}).'
                : question.explanation,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFD1D5DB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final bool isLast = _currentIndex >= _questions.length - 1;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _nextQuestion,
        icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
        label: Text(
          isLast ? 'Finish Challenge' : 'Next Question',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isLast
              ? const Color(0xFFF59E0B)
              : const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
