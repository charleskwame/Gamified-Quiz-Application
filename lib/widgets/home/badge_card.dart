import 'package:flutter/material.dart';
import '../../models/badge.dart';

/// A card displaying a badge, with unlocked/locked visual state.
class BadgeCard extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;

  const BadgeCard({super.key, required this.badge, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05121826),
            blurRadius: 10,
            offset: Offset(0, 4),
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
                color: badge.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock_rounded,
                color: isUnlocked ? badge.color : const Color(0xFF6B7280),
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121826),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
