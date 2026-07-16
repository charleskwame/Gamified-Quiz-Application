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
    final isTopStat =
        titleLabel == 'HIGHEST SCORE' || titleLabel == 'TOP STREAK';

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
        children: [
          // Avatar with crown indicator for #1
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF003F91).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isTopStat
                    ? const Color(0xFFFFD700).withValues(alpha: 0.5)
                    : const Color(0xFF003F91).withValues(alpha: 0.2),
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
                        color: Color(0xFF003F91),
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF003F91),
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
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (isTopStat) const SizedBox(width: 6),
                    if (isTopStat)
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
                    color: Color(0xFF121826),
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
            color: isTopStat
                ? const Color(0xFFFFD700)
                : const Color(0xFF003F91),
            size: 28,
          ),
        ],
      ),
    );
  }
}
