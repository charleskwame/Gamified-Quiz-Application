import 'package:flutter/material.dart';

/// A glass-morphism HUD-style stats panel displaying player metrics
/// in a horizontal row with animated count-up values.
class GameStatPanel extends StatelessWidget {
  final int questionsAnswered;
  final int accuracyPercent;
  final int streakNumber;
  final int totalScore;

  const GameStatPanel({
    super.key,
    required this.questionsAnswered,
    required this.accuracyPercent,
    required this.streakNumber,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.forum_rounded,
              value: '$questionsAnswered',
              label: 'Attempted',
              iconColor: const Color(0xFF6366F1),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.track_changes_rounded,
              value: '$accuracyPercent%',
              label: 'Accuracy',
              iconColor: const Color(0xFF4ADE80),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department_rounded,
              value: '$streakNumber',
              label: 'Streak',
              iconColor: const Color(0xFFFF5722),
            ),
          ),
          _divider(),
          Expanded(
            child: _StatItem(
              icon: Icons.emoji_events_rounded,
              value:
                  '${totalScore >= 1000 ? '${(totalScore / 1000).toStringAsFixed(1)}k' : totalScore}',
              label: 'Score',
              iconColor: const Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFF003F91).withValues(alpha: 0.15),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 6),
        _AnimatedCountUp(
          value: value,
          style: TextStyle(
            color: const Color(0xFF003F91),
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF003F91).withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AnimatedCountUp extends StatelessWidget {
  final String value;
  final TextStyle style;

  const _AnimatedCountUp({required this.value, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: 0,
        end:
            double.tryParse(
              value.replaceAll('%', '').replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0,
      ),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        String display;
        if (value.contains('%')) {
          display = '${val.round()}%';
        } else if (value.contains('k')) {
          display = '${(val / 1000).toStringAsFixed(1)}k';
        } else {
          display = val.round().toString();
        }
        return Text(display, style: style);
      },
    );
  }
}
