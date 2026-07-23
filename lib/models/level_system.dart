import 'package:flutter/material.dart';

/// Defines a single level with its name and cumulative XP requirement.
class LevelDef {
  final int level;
  final String name;
  final int xpRequired; // cumulative XP needed to reach this level

  const LevelDef({
    required this.level,
    required this.name,
    required this.xpRequired,
  });
}

/// Static system that defines all levels and provides helper methods.
class LevelSystem {
  LevelSystem._();

  /// All levels in order. The first level (index 0) is the starting level.
  /// XP requirements have been doubled to make progression slower and more meaningful.
  static const List<LevelDef> levels = [
    LevelDef(level: 1, name: 'Rookie', xpRequired: 0),
    LevelDef(level: 2, name: 'Amateur', xpRequired: 150),
    LevelDef(level: 3, name: 'Scholar', xpRequired: 300),
    LevelDef(level: 4, name: 'Apprentice', xpRequired: 450),
    LevelDef(level: 5, name: 'Specialist', xpRequired: 600),
    LevelDef(level: 6, name: 'Expert', xpRequired: 750),
    LevelDef(level: 7, name: 'Master', xpRequired: 900),
    LevelDef(level: 8, name: 'Grandmaster', xpRequired: 1050),
    LevelDef(level: 9, name: 'Legend', xpRequired: 1200),
    LevelDef(level: 10, name: 'Mythic', xpRequired: 1350),
    LevelDef(level: 11, name: 'Transcendent', xpRequired: 1500),
    LevelDef(level: 12, name: 'Immortal', xpRequired: 1650),
    LevelDef(level: 13, name: 'Cosmic', xpRequired: 1800),
    LevelDef(level: 14, name: 'Celestial', xpRequired: 1950),
    LevelDef(level: 15, name: 'Divine', xpRequired: 2100),
  ];

  /// Returns the user's current level based on total score.
  static LevelDef getLevelByScore(int score) {
    LevelDef current = levels.first;
    for (final lvl in levels) {
      if (score >= lvl.xpRequired) {
        current = lvl;
      } else {
        break;
      }
    }
    return current;
  }

  /// Returns the next level the user hasn't reached yet, or null if max level.
  static LevelDef? getNextLevel(int score) {
    for (final lvl in levels) {
      if (score < lvl.xpRequired) {
        return lvl;
      }
    }
    return null;
  }

  /// Returns the levels the user has passed (including current).
  static List<LevelDef> getUnlockedLevels(int score) {
    final unlocked = <LevelDef>[];
    for (final lvl in levels) {
      if (score >= lvl.xpRequired) {
        unlocked.add(lvl);
      }
    }
    return unlocked;
  }

  /// Returns all levels the user hasn't unlocked yet.
  static List<LevelDef> getLockedLevels(int score) {
    final locked = <LevelDef>[];
    for (final lvl in levels) {
      if (score < lvl.xpRequired) {
        locked.add(lvl);
      }
    }
    return locked;
  }

  /// Returns 0.0–1.0 progress toward the next level.
  static double getXpProgress(int score) {
    final current = getLevelByScore(score);
    final next = getNextLevel(score);
    if (next == null) return 1.0; // max level
    final needed = next.xpRequired - current.xpRequired;
    if (needed <= 0) return 1.0;
    final earned = score - current.xpRequired;
    return (earned / needed).clamp(0.0, 1.0);
  }

  /// Returns XP earned in the current level.
  static int getXpInCurrentLevel(int score) {
    final current = getLevelByScore(score);
    return score - current.xpRequired;
  }

  /// Returns total XP needed to reach the next level.
  static int getXpToNextLevel(int score) {
    final current = getLevelByScore(score);
    final next = getNextLevel(score);
    if (next == null) return 0;
    return next.xpRequired - current.xpRequired;
  }

  /// Returns the number (level numer) the user is on.
  static int getLevelNumber(int score) {
    return getLevelByScore(score).level;
  }

  /// Returns the name of the user's current level.
  static String getLevelName(int score) {
    return getLevelByScore(score).name;
  }

  /// Gradient colors for each level badge — gets more intense at higher levels.
  static List<Color> getLevelColors(int level) {
    const colorPairs = [
      [Color(0xFF003F91), Color(0xFF003F91)], // 1-2: Purple
      [Color(0xFF3B82F6), Color(0xFF06B6D4)], // 3-4: Blue
      [Color(0xFF10B981), Color(0xFF34D399)], // 5-6: Green
      [Color(0xFFF59E0B), Color(0xFFF97316)], // 7-8: Orange
      [Color(0xFFEF4444), Color(0xFFEC4899)], // 9-10: Red/Pink
      [Color(0xFFD946EF), Color(0xFFA855F7)], // 11-12: Magenta/Purple
      [Color(0xFFFFD700), Color(0xFFFF8C00)], // 13-14: Gold/Orange
      [Color(0xFFFFFFFF), Color(0xFF94A3B8)], // 15+: White/Silver
    ];
    final index = (level - 1) ~/ 2;
    if (index >= colorPairs.length) return colorPairs.last;
    return colorPairs[index];
  }
}
