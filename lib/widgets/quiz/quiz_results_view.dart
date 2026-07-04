import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/badge.dart';

/// Displays the quiz completion/results screen with game-like UI.
class QuizResultsView extends StatefulWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final bool isOffline;
  final List<String> newlyUnlockedBadges;
  final String? quoteText;
  final String? quoteAuthor;
  final VoidCallback onBack;
  final int oldLevel;
  final int updatedTotalScore;
  final String? avatarUrl;
  final String displayName;

  const QuizResultsView({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.isOffline,
    required this.newlyUnlockedBadges,
    required this.quoteText,
    required this.quoteAuthor,
    required this.onBack,
    required this.oldLevel,
    required this.updatedTotalScore,
    this.avatarUrl,
    this.displayName = 'Scholar',
  });

  @override
  State<QuizResultsView> createState() => _QuizResultsViewState();
}

class _QuizResultsViewState extends State<QuizResultsView>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scoreCounterController;
  late AnimationController _starsController;
  late Animation<double> _scoreAnimation;
  int _displayScore = 0;
  int _starCount = 0;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _scoreCounterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _starsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scoreAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scoreCounterController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scoreCounterController.addListener(() {
      setState(() {
        _displayScore = (_scoreAnimation.value * widget.score).round();
      });
    });

    _starsController.addListener(() {
      setState(() {
        _starCount = (_starsController.value * _calculateStars()).round();
      });
    });

    // Start animations after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accuracy = widget.correctAnswers / widget.totalQuestions;
      if (accuracy >= 0.50) {
        _confettiController.play();
      }
      _scoreCounterController.forward();
      _starsController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreCounterController.dispose();
    _starsController.dispose();
    super.dispose();
  }

  int _calculateStars() {
    final accuracy = widget.correctAnswers / widget.totalQuestions;
    if (accuracy >= 0.95) return 5;
    if (accuracy >= 0.80) return 4;
    if (accuracy >= 0.65) return 3;
    if (accuracy >= 0.50) return 2;
    if (accuracy >= 0.30) return 1;
    return 0;
  }

  String _getRankFromAccuracy() {
    final accuracy = widget.correctAnswers / widget.totalQuestions;
    if (accuracy >= 0.90) return 'S';
    if (accuracy >= 0.80) return 'A';
    if (accuracy >= 0.70) return 'B';
    if (accuracy >= 0.60) return 'C';
    if (accuracy >= 0.50) return 'D';
    return 'E';
  }

  Widget _buildRankMedal() {
    final rank = _getRankFromAccuracy().toLowerCase();
    return SvgPicture.asset(
      'lib/assets/rank_icons/$rank-rank-medal.svg',
      height: 80,
      width: 80,
    );
  }

  String _getGradeText() {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    if (accuracy >= 90) return 'S Rank';
    if (accuracy >= 80) return 'A Rank';
    if (accuracy >= 70) return 'B Rank';
    if (accuracy >= 60) return 'C Rank';
    if (accuracy >= 50) return 'D Rank';
    return 'E Rank';
  }

  Color _getGradeColor() {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    if (accuracy >= 90) return const Color(0xFFFFD700);
    if (accuracy >= 80) return const Color(0xFF4ADE80);
    if (accuracy >= 70) return const Color(0xFF6366F1);
    if (accuracy >= 60) return const Color(0xFFF59E0B);
    if (accuracy >= 50) return const Color(0xFFEF4444);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = (widget.correctAnswers / widget.totalQuestions * 100)
        .round();
    final stars = _calculateStars();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111C4A)],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // ─── Rank Medal ──────────────────────────
                            _buildRankMedal(),
                            const SizedBox(height: 16),

                            // ─── Grade Text ─────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getGradeColor().withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getGradeColor().withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                _getGradeText(),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: _getGradeColor(),
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Challenge Completed!',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.isOffline
                                  ? 'Offline session completed. Points are stored locally.'
                                  : 'Great job! Your profile stats have been updated.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ─── Stars ──────────────────────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(stars, (index) {
                                final bool isFilled = index < _starCount;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(
                                      isFilled
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      key: ValueKey(isFilled),
                                      size: 40,
                                      color: isFilled
                                          ? const Color(0xFFFFD700)
                                          : const Color(0xFF4B5565),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 32),

                            // ─── Results card ───────────────────────────
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2246),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF2D3361),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem(
                                    'SCORE',
                                    '+$_displayScore pts',
                                    const Color(0xFF6366F1),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: const Color(0xFF2D3361),
                                  ),
                                  _buildStatItem(
                                    'CORRECT',
                                    '${widget.correctAnswers}/${widget.totalQuestions}',
                                    const Color(0xFF4ADE80),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: const Color(0xFF2D3361),
                                  ),
                                  _buildStatItem(
                                    'ACCURACY',
                                    '$accuracy%',
                                    const Color(0xFFF59E0B),
                                  ),
                                ],
                              ),
                            ),

                            // ─── Badges Earned ──────────────────────────
                            if (widget.newlyUnlockedBadges.isNotEmpty) ...[
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
                                children: widget.newlyUnlockedBadges.map((
                                  badgeId,
                                ) {
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

                            const SizedBox(height: 32),

                            // ─── Back to Menu Button ────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: widget.onBack,
                                icon: const Icon(Icons.home_rounded),
                                label: const Text('Back to Course Selection'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            // ─── Motivational Quote ─────────────────────
                            if (widget.quoteText != null) ...[
                              const SizedBox(height: 28),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1E3E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF2D3361),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.format_quote_rounded,
                                      color: Color(0xFF6366F1),
                                      size: 28,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      widget.quoteText!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD1D5DB),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '— ${widget.quoteAuthor}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: -pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                maxBlastForce: 30,
                minBlastForce: 10,
                emissionFrequency: 0.05,
                numberOfParticles: 30,
                gravity: 0.2,
                colors: const [
                  Color(0xFFFFD700),
                  Color(0xFF4ADE80),
                  Color(0xFF6366F1),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                  Colors.white,
                ],
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
      ],
    );
  }
}
