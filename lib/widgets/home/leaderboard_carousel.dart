import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_rank.dart';
import '../../services/database_service.dart';
import 'leaderboard_card.dart';

/// A horizontally swipeable carousel that highlights top performers:
/// - Highest streak
/// - Highest total score
/// - Highest points in each subject (Computer Architecture, Software Engineering, Computer Networking)
///
/// Cards auto-advance every 4 seconds and use the same gradient/shape as ScoreDashboardCard.
/// Uses AnimatedSwitcher instead of PageView to avoid scroll conflicts with the parent SingleChildScrollView.
class LeaderboardCarousel extends StatefulWidget {
  const LeaderboardCarousel({super.key});

  @override
  State<LeaderboardCarousel> createState() => _LeaderboardCarouselState();
}

class _LeaderboardCarouselState extends State<LeaderboardCarousel> {
  final DatabaseService _dbService = DatabaseService();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll(int totalCards) {
    _autoScrollTimer?.cancel();
    if (totalCards <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _goToPage((_currentPage + 1) % totalCards);
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserRank>>(
      stream: _dbService.getRankingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rankings = snapshot.data ?? [];

        if (rankings.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white38,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'No rankings yet. Start playing!',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          );
        }

        // Compute top performers
        final topStreak = rankings.reduce(
          (a, b) => a.streakNumber >= b.streakNumber ? a : b,
        );
        final topScore = rankings.reduce((a, b) => a.score >= b.score ? a : b);
        final topCA = rankings.reduce(
          (a, b) => a.computerArchitecturePoints >= b.computerArchitecturePoints
              ? a
              : b,
        );
        final topSE = rankings.reduce(
          (a, b) => a.softwareEngineeringPoints >= b.softwareEngineeringPoints
              ? a
              : b,
        );
        final topCN = rankings.reduce(
          (a, b) =>
              a.computerNetworkingPoints >= b.computerNetworkingPoints ? a : b,
        );

        final cards = <Widget>[
          if (topStreak.streakNumber > 0)
            LeaderboardCard(
              titleLabel: 'TOP STREAK',
              userName: topStreak.name,
              statValue: '${topStreak.streakNumber}-Day Streak',
              avatarUrl: topStreak.avatarUrl,
              icon: Icons.local_fire_department_rounded,
            ),
          LeaderboardCard(
            titleLabel: 'HIGHEST SCORE',
            userName: topScore.name,
            statValue: '${topScore.score} Points',
            avatarUrl: topScore.avatarUrl,
            icon: Icons.emoji_events_rounded,
          ),
          LeaderboardCard(
            titleLabel: 'COMPUTER ARCHITECTURE',
            userName: topCA.name,
            statValue: '${topCA.computerArchitecturePoints} Points',
            avatarUrl: topCA.avatarUrl,
            icon: Icons.memory_rounded,
          ),
          LeaderboardCard(
            titleLabel: 'SOFTWARE ENGINEERING',
            userName: topSE.name,
            statValue: '${topSE.softwareEngineeringPoints} Points',
            avatarUrl: topSE.avatarUrl,
            icon: Icons.terminal_rounded,
          ),
          LeaderboardCard(
            titleLabel: 'COMPUTER NETWORKING',
            userName: topCN.name,
            statValue: '${topCN.computerNetworkingPoints} Points',
            avatarUrl: topCN.avatarUrl,
            icon: Icons.lan_rounded,
          ),
        ];

        // Start auto-scroll after first build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll(cards.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 90,
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  // Swipe left → next page, swipe right → previous page
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0) {
                      _goToPage((_currentPage + 1) % cards.length);
                    } else {
                      _goToPage(
                        (_currentPage - 1 + cards.length) % cards.length,
                      );
                    }
                  }
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Padding(
                    key: ValueKey(_currentPage),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: cards[_currentPage],
                  ),
                ),
              ),
            ),
            if (cards.length > 1) ...[
              const SizedBox(height: 10),
              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(cards.length, (index) {
                  final isActive = index == _currentPage;
                  return GestureDetector(
                    onTap: () => _goToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF1E293B).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }
}
