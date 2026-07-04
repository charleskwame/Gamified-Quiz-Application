import 'package:flutter/material.dart';
import '../../models/badge.dart';

/// A dark-themed game-style card displaying a badge, with unlocked/locked visual state.
class BadgeCard extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;

  const BadgeCard({super.key, required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? badge.color.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: badge.color.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock_rounded,
                color: isUnlocked ? badge.color : Colors.white38,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isUnlocked ? Colors.white : Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: isUnlocked ? 0.5 : 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
