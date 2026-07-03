import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A card in the leaderboard carousel styled with the dark modern game aesthetic.
class LeaderboardCard extends StatelessWidget {
  final String titleLabel;
  final String userName;
  final String statValue;
  final String? avatarUrl;
  final IconData icon;

  const LeaderboardCard({
    super.key,
    required this.titleLabel,
    required this.userName,
    required this.statValue,
    this.avatarUrl,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with crown indicator for #1
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    titleLabel == 'HIGHEST SCORE' || titleLabel == 'TOP STREAK'
                    ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: SvgPicture.network(
                      avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white60,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Colors.white60,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      titleLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (titleLabel == 'HIGHEST SCORE' ||
                        titleLabel == 'TOP STREAK')
                      const SizedBox(width: 6),
                    if (titleLabel == 'HIGHEST SCORE' ||
                        titleLabel == 'TOP STREAK')
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  statValue,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Icon
          Icon(
            icon,
            color: titleLabel == 'HIGHEST SCORE' || titleLabel == 'TOP STREAK'
                ? const Color(0xFFFFD700)
                : Colors.white38,
            size: 28,
          ),
        ],
      ),
    );
  }
}
