import 'package:flutter/material.dart';
import '../../models/badge.dart';

/// Displays the quiz completion/results screen.
class QuizResultsView extends StatelessWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final bool isOffline;
  final List<String> newlyUnlockedBadges;
  final String? quoteText;
  final String? quoteAuthor;
  final VoidCallback onBack;

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
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (correctAnswers / totalQuestions * 100).round();

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
                        isOffline
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
                                  '+$score pts',
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

                      if (newlyUnlockedBadges.isNotEmpty) ...[
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
                          children: newlyUnlockedBadges.map((badgeId) {
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
                          onPressed: onBack,
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
                      if (quoteText != null) ...[
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDCE3F0)),
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
                                quoteText!,
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
                                '— $quoteAuthor',
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
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
