import 'package:flutter/material.dart';
import '../../models/badge.dart';

/// A light-themed card displaying a badge, with unlocked/locked visual state.
class BadgeCard extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;

  const BadgeCard({super.key, required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFECF8F8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? badge.color.withValues(alpha: 0.3)
              : const Color(0xFF003F91).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (isUnlocked)
            BoxShadow(
              color: badge.color.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? badge.color.withValues(alpha: 0.15)
                    : const Color(0xFF003F91).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock_rounded,
                color: isUnlocked
                    ? badge.color
                    : const Color(0xFF003F91).withValues(alpha: 0.3),
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
                color: isUnlocked
                    ? const Color(0xFF003F91)
                    : const Color(0xFF003F91).withValues(alpha: 0.5),
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
                color: const Color(
                  0xFF003F91,
                ).withValues(alpha: isUnlocked ? 0.5 : 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
