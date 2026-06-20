import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../models/badge.dart';
import '../services/database_service.dart';

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

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  final DatabaseService _db = DatabaseService();
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

  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuizQuestions() async {
    try {
      List<Question> loadedQuestions = [];
      if (widget.isOffline) {
        loadedQuestions = await _db.loadOfflineQuestions(widget.category);
      } else {
        loadedQuestions = await _db.getQuestionsByCategory(widget.category);
      }

      if (loadedQuestions.isEmpty) {
        throw Exception('No questions available.');
      }

      // Shuffle and take up to 10 questions
      loadedQuestions.shuffle();
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

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 15;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    setState(() {
      _isAnswered = true;
      _selectedOption = ''; // Mark unanswered
    });
  }

  void _selectAnswer(String option) {
    if (_isAnswered) return;
    _timer?.cancel();

    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect = option.trim().toLowerCase().startsWith(
          currentQuestion.correctAnswer.toLowerCase(),
        );

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      if (isCorrect) {
        _correctAnswers++;
        _score += widget.isTimed ? 3 : 1;
      }
    });
  }

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

    if (mounted) {
      setState(() {
        _isLoading = false;
        _newlyUnlockedBadges = unlocked;
        _currentIndex = _questions.length; // Triggers completion state
      });

      if (unlocked.isNotEmpty) {
        _showBadgeCelebrationDialog(unlocked);
        for (int i = 0; i < unlocked.length; i++) {
          Future.delayed(Duration(seconds: i * 4), () {
            if (mounted) {
              _showTopToast(unlocked[i]);
            }
          });
        }
      }
    }
  }

  void _showTopToast(String badgeId) {
    final badge = allBadges.firstWhere((b) => b.id == badgeId);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _TopToastWidget(
            badge: badge,
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  void _showBadgeCelebrationDialog(List<String> badgeIds) {
    final newlyUnlocked = allBadges.where((b) => badgeIds.contains(b.id)).toList();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFD700),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Badge Earned!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF121826),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  newlyUnlocked.length == 1
                      ? 'Congratulations! You unlocked a new achievement.'
                      : 'Wow! You unlocked ${newlyUnlocked.length} new achievements!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: newlyUnlocked.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final badge = newlyUnlocked[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: badge.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: badge.color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(badge.icon, color: badge.color, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    badge.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF121826),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    badge.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF4B5565),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Awesome!'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B5FEF)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Assembling your challenge...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF121826),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fetching premium questions from the bank',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Results screen
    if (_currentIndex >= _questions.length) {
      final accuracy = (_correctAnswers / _questions.length * 100).round();
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 100,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(height: 24),
                Text(
                  'Challenge Completed!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isOffline
                      ? 'Offline session completed. Points are stored locally.'
                      : 'Great job! Your profile stats have been updated.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Results card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE6EAF2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'SCORE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+$_score pts',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 40, color: const Color(0xFFE6EAF2)),
                      Column(
                        children: [
                          const Text(
                            'ACCURACY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$accuracy%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF121826),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (_newlyUnlockedBadges.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    '🎉 BADGES EARNED! 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _newlyUnlockedBadges.map((badgeId) {
                      final badge = allBadges.firstWhere((b) => b.id == badgeId);
                      return Chip(
                        avatar: Icon(badge.icon, color: Colors.white, size: 16),
                        label: Text(badge.name),
                        backgroundColor: badge.color,
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Course Selection'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Quit Challenge?'),
                  content: const Text('Are you sure you want to quit? Your progress for this challenge will be lost.'),
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
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linear Timer Progress bar (only at top if Timed Mode)
              if (widget.isTimed) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _timeLeft / 15,
                    minHeight: 6,
                    color: _timeLeft <= 4 ? Colors.red : Theme.of(context).colorScheme.primary,
                    backgroundColor: const Color(0xFFE6EAF2),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Question Text Card (with internal question number and timer)
              Container(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _timeLeft <= 4 ? Colors.red.shade50 : const Color(0xFFF4F6FB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer_rounded,
                                  size: 14,
                                  color: _timeLeft <= 4 ? Colors.red : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_timeLeft}s',
                                  style: TextStyle(
                                    color: _timeLeft <= 4 ? Colors.red : const Color(0xFF121826),
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
              ),
              const SizedBox(height: 24),

              // Option Buttons
              ...question.options.map((option) {
                final isSelected = _selectedOption == option;
                final isCorrectOption = option.trim().toLowerCase().startsWith(
                      question.correctAnswer.toLowerCase(),
                    );

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
                                    fontWeight: isSelected || (_isAnswered && isCorrectOption)
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
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Explanation & Next Button
              if (_isAnswered) ...[
                const SizedBox(height: 16),
                Container(
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
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _nextQuestion,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _currentIndex < _questions.length - 1 ? 'Next Question' : 'Finish Challenge',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final BadgeDefinition badge;
  final VoidCallback onDismiss;

  const _TopToastWidget({
    required this.badge,
    required this.onDismiss,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _yAnimation = Tween<double>(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF09262A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF0D3F45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF09262A).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.badge.icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🏆 Badge Earned!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlocked "${widget.badge.name}"',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
              onPressed: () {
                _controller.reverse().then((_) {
                  widget.onDismiss();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
