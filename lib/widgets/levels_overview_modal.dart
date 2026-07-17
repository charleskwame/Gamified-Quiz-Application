import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/level_system.dart';

/// A full-screen modal showing all available levels, past levels,
/// progress toward the next, and requirements for all levels.
/// Uses the app's light aesthetic matching the shop and player header.
class LevelsOverviewModal extends StatelessWidget {
  final int totalScore;
  final String? avatarUrl;
  final String displayName;

  const LevelsOverviewModal({
    super.key,
    required this.totalScore,
    this.avatarUrl,
    required this.displayName,
  });

  /// Shows the modal as a bottom sheet with some extra height.
  static void show({
    required BuildContext context,
    required int totalScore,
    String? avatarUrl,
    required String displayName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LevelsOverviewModal(
        totalScore: totalScore,
        avatarUrl: avatarUrl,
        displayName: displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelSystem.getLevelByScore(totalScore);
    final nextLevel = LevelSystem.getNextLevel(totalScore);
    final progress = LevelSystem.getXpProgress(totalScore);
    final xpInLevel = LevelSystem.getXpInCurrentLevel(totalScore);
    final xpToNext = LevelSystem.getXpToNextLevel(totalScore);
    final unlockedLevels = LevelSystem.getUnlockedLevels(totalScore);
    final lockedLevels = LevelSystem.getLockedLevels(totalScore);
    final levelColors = LevelSystem.getLevelColors(currentLevel.level);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF003F91).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Levels',
                          style: TextStyle(
                            color: Color(0xFF003F91),
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF003F91,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF003F91),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // ── Current Level Hero Section ──
                SliverToBoxAdapter(
                  child: _buildCurrentLevelHero(
                    currentLevel: currentLevel,
                    nextLevel: nextLevel,
                    progress: progress,
                    xpInLevel: xpInLevel,
                    xpToNext: xpToNext,
                    levelColors: levelColors,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── All Levels List ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          'All Levels',
                          style: TextStyle(
                            color: const Color(
                              0xFF003F91,
                            ).withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: const Color(
                              0xFF003F91,
                            ).withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Unlocked levels
                ...unlockedLevels.map(
                  (lvl) => SliverToBoxAdapter(
                    child: _buildLevelRow(
                      level: lvl,
                      isUnlocked: true,
                      isCurrent: lvl.level == currentLevel.level,
                      currentScore: totalScore,
                    ),
                  ),
                ),

                // Locked levels
                ...lockedLevels.map(
                  (lvl) => SliverToBoxAdapter(
                    child: _buildLevelRow(
                      level: lvl,
                      isUnlocked: false,
                      isCurrent: false,
                      currentScore: totalScore,
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Large hero section showing the current level with avatar, name, and XP bar.
  Widget _buildCurrentLevelHero({
    required LevelDef currentLevel,
    required LevelDef? nextLevel,
    required double progress,
    required int xpInLevel,
    required int xpToNext,
    required List<Color> levelColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: levelColors[0].withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColors[0].withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Level number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: levelColors),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: levelColors[0].withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Level ${currentLevel.level}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Level name
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentLevel.name,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF121826),
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: levelColors,
                ).createShader(const Rect.fromLTWH(0, 0, 200, 60)),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFF003F91),
                    Color(0xFF003F91),
                    Color(0xFFFFD700),
                    Color(0xFF4ADE80),
                    Color(0xFF003F91),
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF003F91).withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SvgPicture.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 36,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF9CA3AF),
                size: 40,
              ),
            ),

          const SizedBox(height: 20),

          // XP Progress section
          if (nextLevel != null) ...[
            // XP bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$xpInLevel / $xpToNext XP to ${nextLevel.name}',
              style: TextStyle(
                color: const Color(0xFF003F91).withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            // Max level reached
            Text(
              'Maximum Level Reached!',
              style: TextStyle(
                color: levelColors[0],
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Total XP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$totalScore Total XP',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A single row in the all-levels list.
  Widget _buildLevelRow({
    required LevelDef level,
    required bool isUnlocked,
    required bool isCurrent,
    required int currentScore,
  }) {
    final colors = LevelSystem.getLevelColors(level.level);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrent
            ? colors[0].withValues(alpha: 0.08)
            : isUnlocked
            ? Colors.white
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? colors[0].withValues(alpha: 0.3)
              : const Color(0xFF003F91).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          // Level number indicator
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isUnlocked ? LinearGradient(colors: colors) : null,
              color: isUnlocked ? null : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${level.level}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isUnlocked ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Level name and XP requirement
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isUnlocked
                        ? const Color(0xFF121826)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked
                      ? level.xpRequired == 0
                            ? 'Starting level'
                            : '${level.xpRequired} XP required'
                      : '${level.xpRequired} XP required',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isUnlocked
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),

          // Status icon
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF003F91).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF003F91).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'CURRENT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: colors[0],
                  letterSpacing: 0.5,
                ),
              ),
            )
          else if (isUnlocked && level.level > 1)
            Icon(
              Icons.check_circle_rounded,
              color: const Color(0xFF4ADE80),
              size: 22,
            )
          else if (!isUnlocked)
            Icon(Icons.lock_rounded, color: const Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }
}
