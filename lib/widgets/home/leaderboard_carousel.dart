import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_rank.dart';
import '../../services/database_service.dart';
import 'leaderboard_card.dart';

/// A horizontally swipeable carousel that highlights top performers.
///
/// Uses Flutter's native [PageView] with a manual auto-advance timer for
/// complete reliability — no third-party carousel packages involved.
class LeaderboardCarousel extends StatefulWidget {
  const LeaderboardCarousel({super.key});

  @override
  State<LeaderboardCarousel> createState() => _LeaderboardCarouselState();
}

class _LeaderboardCarouselState extends State<LeaderboardCarousel> {
  final DatabaseService _dbService = DatabaseService();
  final PageController _pageController = PageController();

  StreamSubscription<List<UserRank>>? _subscription;
  List<Widget> _cachedCards = const [];
  bool _isLoading = true;
  String? _loadError;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  static List<Widget> _computeCards(List<UserRank> rankings) {
    if (rankings.isEmpty) return const [];

    final topStreak = rankings.reduce(
      (a, b) => a.streakNumber >= b.streakNumber ? a : b,
    );
    final topScore = rankings.reduce((a, b) => a.score >= b.score ? a : b);
    final topCA = rankings.reduce(
      (a, b) =>
          a.computerArchitecturePoints >= b.computerArchitecturePoints ? a : b,
    );
    final topSE = rankings.reduce(
      (a, b) =>
          a.softwareEngineeringPoints >= b.softwareEngineeringPoints ? a : b,
    );
    final topCN = rankings.reduce(
      (a, b) =>
          a.computerNetworkingPoints >= b.computerNetworkingPoints ? a : b,
    );

    return [
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
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_cachedCards.length <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _cachedCards.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _subscription = _dbService.getRankingsStream().listen(
      (rankings) {
        if (!mounted) return;
        final newCards = _computeCards(rankings);
        setState(() {
          _isLoading = false;
          _loadError = null;
          _cachedCards = newCards;
          if (_currentPage >= _cachedCards.length) {
            _currentPage = 0;
          }
        });
        _startAutoScroll();
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _loadError = error.toString();
          _cachedCards = const [];
          _currentPage = 0;
        });
        _autoScrollTimer?.cancel();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF003F91).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Rankings are unavailable right now.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (_cachedCards.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF003F91).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'No rankings yet. Start playing!',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cachedCards.length,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _cachedCards[index],
              );
            },
          ),
        ),
        if (_cachedCards.length > 1) ...[
          const SizedBox(height: 10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_cachedCards.length, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF003F91)
                        : const Color(0xFF003F91).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
