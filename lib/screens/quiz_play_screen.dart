import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';
import '../models/badge.dart';
import '../services/database_service.dart';
import '../services/deepseek_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  int _consecutiveIncorrect = 0;
  int _consecutiveCorrect = 0;
  AnimationController? _aiButtonAnimationController;
  AnimationController? _progressAnimationController;
  final List<Question> _incorrectQuestions = [];

  // Fisher-Yates Shuffle Algorithm to ensure uniform random distribution
  void _fisherYatesShuffle<T>(List<T> list) {
    final random = Random();
    for (int i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
  }

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

  @override
  void initState() {
    super.initState();
    _loadQuizQuestions();
    _aiButtonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnimationController?.dispose();
    _aiButtonAnimationController?.dispose();
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

      // Shuffle and take up to 10 questions using Fisher-Yates algorithm
      _fisherYatesShuffle(loadedQuestions);
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

    // Start from 1.0 (full) and animate down to 0.0 (empty)
    _progressAnimationController!.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // We use the animation for smooth visual; this periodic timer is only
      // for the numeric countdown display and timeout safety net.
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
      _selectedOption = ''; // Mark unanswered
      _consecutiveIncorrect++;
      _consecutiveCorrect = 0;
      _incorrectQuestions.add(currentQuestion);
    });
  }

  void _selectAnswer(String option) {
    if (_isAnswered) return;
    _timer?.cancel();
    _progressAnimationController?.stop();

    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect = option.trim().toLowerCase().startsWith(
      currentQuestion.correctAnswer.toLowerCase(),
    );

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      if (isCorrect) {
        _correctAnswers++;
        _consecutiveCorrect++;
        _consecutiveIncorrect = 0;

        // Points multiplier in challenge (timed) mode
        if (widget.isTimed) {
          // Bonus multiplier: 2nd correct = +0.5, 3rd = +1.0, 4th = +1.5, etc.
          final double bonusMultiplier = (_consecutiveCorrect - 1) * 0.5;
          final double totalMultiplier = 1.0 + bonusMultiplier;
          _score += (3 * totalMultiplier).round();
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

    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_active_date', todayStr);
      final notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? false;
      if (notificationsEnabled) {
        await NotificationService().rescheduleForTomorrow();
      }
    } catch (e) {
      // Ignore preference write/notification scheduling errors
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

      // Load a random motivational quote for the completion screen
      _loadRandomQuote();
    }
  }

  Future<void> _loadRandomQuote() async {
    try {
      final jsonString = await rootBundle.loadString('lib/assets/quotes.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      final List<dynamic> quotesList = data['quotes'];
      if (quotesList.isNotEmpty) {
        final random = Random();
        final randomQuote = quotesList[random.nextInt(quotesList.length)];
        final String text = randomQuote['quote'];
        final String author = randomQuote['author'];
        if (mounted) {
          setState(() {
            _randomQuoteText = text;
            _randomQuoteAuthor = author;
          });
        }
      }
    } catch (_) {
      // Silently fail — quote display is optional
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
    final newlyUnlocked = allBadges
        .where((b) => badgeIds.contains(b.id))
        .toList();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
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
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final badge = newlyUnlocked[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: badge.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: badge.color.withValues(alpha: 0.2),
                          ),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF141053)),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40,
                    ),
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
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.isOffline
                              ? 'Offline session completed. Points are stored locally.'
                              : 'Great job! Your profile stats have been updated.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: const Color(0xFFE6EAF2),
                              ),
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
                              final badge = allBadges.firstWhere(
                                (b) => b.id == badgeId,
                              );
                              return Chip(
                                avatar: Icon(
                                  badge.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(badge.name),
                                backgroundColor: badge.color,
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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

                        // Random motivational quote from quotes.json
                        if (_randomQuoteText != null) ...[
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFDCE3F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: Color(0xFF9CA3AF),
                                  size: 28,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _randomQuoteText!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '— $_randomQuoteAuthor',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ), // Column
                  ), // Padding
                ),
              ); // ConstrainedBox + SingleChildScrollView return
            },
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      floatingActionButton:
          (!widget.isTimed &&
              !widget.isOffline &&
              _consecutiveIncorrect >= 2 &&
              _currentIndex < _questions.length)
          ? _buildAiFloatingButton()
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
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linear Timer Progress bar (only at top if Timed Mode)
                  if (widget.isTimed) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedBuilder(
                        animation: _progressAnimationController!,
                        builder: (context, child) {
                          // Smoothly animate from 1.0 (full) down to 0.0 (empty)
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
                  ),
                  const SizedBox(height: 24),

                  // Option Buttons
                  ...question.options.map((option) {
                    final isSelected = _selectedOption == option;
                    final isCorrectOption = option
                        .trim()
                        .toLowerCase()
                        .startsWith(question.correctAnswer.toLowerCase());

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
                      bgC = Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05);
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
                            onTap: _isAnswered
                                ? null
                                : () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight:
                                            isSelected ||
                                                (_isAnswered && isCorrectOption)
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
                                      color:
                                          stateIcon ==
                                              Icons.check_circle_rounded
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
                            question.explanation.isEmpty ||
                                    question.explanation == 'None.'
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
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
          // Streak multiplier badge (bottom-left corner, only in challenge mode)
          if (widget.isTimed && _consecutiveCorrect >= 2)
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _buildStreakMultiplierBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakMultiplierBadge() {
    final double bonusMultiplier = (_consecutiveCorrect - 1) * 0.5;
    final double totalMultiplier = 1.0 + bonusMultiplier;
    // Display with one decimal place (e.g. 1.5, 2.0, 2.5)
    final String multiplierText = totalMultiplier.toStringAsFixed(1);

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4500).withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 32,
          ),
          Positioned(
            bottom: 10,
            child: Text(
              multiplierText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiFloatingButton() {
    return AnimatedBuilder(
      animation: _aiButtonAnimationController!,
      builder: (context, child) {
        final double scale = 1.0 + (_aiButtonAnimationController!.value * 0.1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Floating bubble hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Need assistance?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Pulsing Floating Action Button
            Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF141053).withValues(alpha: 0.4),
                      blurRadius: 10 * _aiButtonAnimationController!.value,
                      spreadRadius: 3 * _aiButtonAnimationController!.value,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _showAiChatInterface,
                  backgroundColor: const Color(0xFF141053),
                  mini: false,
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAiChatInterface() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiChatBottomSheet(
        category: widget.category,
        incorrectQuestions: _incorrectQuestions,
      ),
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final BadgeDefinition badge;
  final VoidCallback onDismiss;

  const _TopToastWidget({required this.badge, required this.onDismiss});

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
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

    _yAnimation = Tween<double>(
      begin: -120.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

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
          child: Opacity(opacity: _fadeAnimation.value, child: child),
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
              child: Icon(widget.badge.icon, color: Colors.white, size: 24),
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
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.white70,
              ),
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

class _ChatMessage {
  String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _AiChatBottomSheet extends StatefulWidget {
  final String category;
  final List<Question> incorrectQuestions;

  const _AiChatBottomSheet({
    required this.category,
    required this.incorrectQuestions,
  });

  @override
  State<_AiChatBottomSheet> createState() => _AiChatBottomSheetState();
}

class _AiChatBottomSheetState extends State<_AiChatBottomSheet> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            "🤖 **Welcome to DeepSeek AI Study Assistant!**\n\nI am analyzing your quiz performance to prepare tailored study tips. Please wait for my response before asking any questions.",
        isUser: false,
      ),
    );
    _fetchInitialStudyGuide();
  }

  Future<void> _fetchInitialStudyGuide() async {
    if (!mounted) return;
    setState(() {
      _isTyping = true;
    });

    final category = widget.category;
    final wrongQuestionsDetails = widget.incorrectQuestions.isEmpty
        ? "No wrong questions yet. General assistance."
        : widget.incorrectQuestions
              .map(
                (q) =>
                    "- Question: ${q.questionText}\n  Correct Answer: ${q.correctAnswer}",
              )
              .join("\n\n");

    final prompt =
        """
You are an expert AI study tutor inside a gamified quiz application.
The user is currently taking a quiz on "$category".
${widget.incorrectQuestions.isNotEmpty ? "Here are the questions they got wrong so far:\n$wrongQuestionsDetails\n" : ""}
CRITICAL INSTRUCTION: Be extremely direct and straight to the point. Give 1-2 concise bullet points or sentences with study tips. No intros, greetings, or fluff.
""";

    final aiMessage = _ChatMessage(text: "", isUser: false);
    bool addedMessage = false;

    try {
      final stream = DeepseekService.sendMessageStream(
        systemPrompt: prompt,
        messages: [],
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        if (chunk.isNotEmpty) {
          if (!addedMessage) {
            _messages.add(aiMessage);
            addedMessage = true;
            _isTyping = false;
          }
          setState(() {
            aiMessage.text += chunk;
          });
          _scrollToBottom();
        }
      }

      if (mounted && !addedMessage) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: "Welcome! How can I help you with $category today?",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("DeepSeek Initial Guide Error: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "Welcome to your AI Study Tutor! How can I help you with $category today?",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty || _isTyping) return;

    final text = userMessage.trim();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    final category = widget.category;
    final wrongQuestionsDetails = widget.incorrectQuestions
        .map(
          (q) =>
              "- Question: ${q.questionText}\n  Correct Option: ${q.correctAnswer}",
        )
        .join("\n\n");

    final systemPrompt =
        """
You are an expert AI study tutor inside a gamified quiz application.
The user is currently taking a quiz on "$category".
${widget.incorrectQuestions.isNotEmpty ? "Questions answered incorrectly so far:\n$wrongQuestionsDetails\n" : ""}
CRITICAL INSTRUCTION: Be extremely direct and straight to the point. Answer immediately without conversational filler or intros like 'Hello!' or 'Sure!'. Use concise sentences or short bullet points.
""";

    // Build conversation history for DeepSeek (system prompt handled separately)
    final List<Map<String, String>> conversationMessages = [];
    for (var msg in _messages) {
      conversationMessages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    final aiMessage = _ChatMessage(text: "", isUser: false);
    bool addedMessage = false;

    try {
      final stream = DeepseekService.sendMessageStream(
        systemPrompt: systemPrompt,
        messages: conversationMessages,
      );

      await for (final chunk in stream) {
        if (!mounted) break;
        if (chunk.isNotEmpty) {
          if (!addedMessage) {
            _messages.add(aiMessage);
            addedMessage = true;
            _isTyping = false;
          }
          setState(() {
            aiMessage.text += chunk;
          });
          _scrollToBottom();
        }
      }

      if (mounted && !addedMessage) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "I read your message but couldn't formulate a response. Let me know if you have another question!",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint("DeepSeek Chat Exception: $e");
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text:
                  "Sorry, an issue occurred with the AI assistant service. Please check your network or try again later.",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle and header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF141053),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'DeepSeek AI Study Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Color(0xFF141053),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DeepSeek is thinking...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: message.isUser
                          ? const LinearGradient(
                              colors: [Color(0xFF141053), Color(0xFF141053)],
                            )
                          : null,
                      color: message.isUser ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 16),
                      ),
                    ),
                    child: message.isUser
                        ? Text(
                            message.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          )
                        : MarkdownBody(
                            data: message.text,
                            selectable: true,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(
                                  Theme.of(context),
                                ).copyWith(
                                  p: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  listBullet: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                  strong: TextStyle(
                                    color: Colors.grey.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Input field
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 12,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isTyping,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: _isTyping
                          ? 'Please wait for DeepSeek to respond...'
                          : 'Ask DeepSeek a follow-up question...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _isTyping
                        ? Colors.grey.shade400
                        : const Color(0xFF141053),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _isTyping
                        ? null
                        : () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
