import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A game-style player header with avatar, level badge, XP progress bar,
/// and streak badge.
class PlayerHeader extends StatelessWidget {
  final String displayName;
  final int totalScore;
  final int streakNumber;
  final int level;
  final double xpProgress; // 0.0 to 1.0
  final String? avatarUrl;
  final String levelName;
  final VoidCallback onStreakTap;
  final VoidCallback? onLevelTap;

  const PlayerHeader({
    super.key,
    required this.displayName,
    required this.totalScore,
    required this.streakNumber,
    required this.level,
    required this.xpProgress,
    this.avatarUrl,
    required this.levelName,
    required this.onStreakTap,
    this.onLevelTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar with glowing ring
        _buildAvatar(),
        const SizedBox(width: 16),
        // Name, level, XP bar
        Expanded(child: _buildPlayerInfo()),
        const SizedBox(width: 12),
        // Streak badge
        if (streakNumber > 0) _buildStreakBadge(),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF808080),
            Color(0xFFB0B0B0),
            Color(0xFFE0E0E0),
            Color(0xFF909090),
            Color(0xFF808080),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF808080).withValues(alpha: 0.08),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E21),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? SvgPicture.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
                      size: 32,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                    size: 32,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name and level badge
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildLevelBadge(),
          ],
        ),
        const SizedBox(height: 6),
        // XP bar
        _buildXpBar(),
        const SizedBox(height: 4),
        // Score text
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFE0E0E0), size: 16),
            const SizedBox(width: 4),
            Text(
              '$totalScore XP',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLevelBadge() {
    return GestureDetector(
      onTap: onLevelTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF808080), Color(0xFFB0B0B0)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF808080).withValues(alpha: 0.08),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              levelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildXpBar() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: xpProgress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF808080), Color(0xFFB0B0B0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF808080,
                              ).withValues(alpha: 0.08),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${(value * 100).round()}% to next level',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStreakBadge() {
    return GestureDetector(
      onTap: onStreakTap,
      child: _PulsingStreak(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF808080).withValues(alpha: 0.2),
                const Color(0xFF808080).withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF808080).withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                '$streakNumber',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'completion${streakNumber > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingStreak extends StatefulWidget {
  final Widget child;
  const _PulsingStreak({required this.child});

  @override
  State<_PulsingStreak> createState() => _PulsingStreakState();
}

class _PulsingStreakState extends State<_PulsingStreak>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnim.value, child: child);
      },
      child: widget.child,
    );
  }
}
