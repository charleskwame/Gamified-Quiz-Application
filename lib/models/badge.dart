import 'package:flutter/material.dart';

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  // Check if this badge is unlocked based on current user stats and latest quiz results
  bool checkUnlock({
    required int score,
    required int computerArchitecturePoints,
    required int computerNetworkingPoints,
    required int softwareEngineeringPoints,
    required int questionsCorrect,
    required int questionsAnswered,
    required int streakNumber,
    required int latestCorrect,
    required bool isTimed,
  }) {
    switch (id) {
      case 'first_steps':
        return questionsAnswered >= 1;
      case 'perfect_score':
        return latestCorrect == 10;
      case 'speed_demon':
        return isTimed;
      case 'streak_starter':
        return streakNumber >= 2;
      case 'streak_master':
        return streakNumber >= 5;
      case 'streak_legend':
        return streakNumber >= 10;
      case 'consistent_player':
        return questionsAnswered >= 50;
      case 'quiz_champion':
        return questionsAnswered >= 100;
      case 'grand_master':
        return questionsAnswered >= 250;
      case 'high_scorer':
        return score >= 500;
      case 'elite_scorer':
        return score >= 1000;
      case 'centurion':
        return score >= 2000;
      case 'arch_initiate':
        return computerArchitecturePoints >= 50;
      case 'arch_expert':
        return computerArchitecturePoints >= 200;
      case 'net_initiate':
        return computerNetworkingPoints >= 50;
      case 'net_expert':
        return computerNetworkingPoints >= 200;
      case 'se_initiate':
        return softwareEngineeringPoints >= 50;
      case 'se_expert':
        return softwareEngineeringPoints >= 200;
      case 'sharp_shooter':
        return latestCorrect >= 8;
      case 'polymath':
        return computerArchitecturePoints > 0 &&
            computerNetworkingPoints > 0 &&
            softwareEngineeringPoints > 0;
      default:
        return false;
    }
  }
}

const List<BadgeDefinition> allBadges = [
  BadgeDefinition(
    id: 'first_steps',
    name: 'First Steps',
    description: 'Completed your first quiz challenge',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF4CAF50),
  ),
  BadgeDefinition(
    id: 'perfect_score',
    name: 'Perfect 10',
    description: 'Scored 10/10 correct answers in a single quiz',
    icon: Icons.star_rounded,
    color: Color(0xFFFFD700),
  ),
  BadgeDefinition(
    id: 'speed_demon',
    name: 'Speed Demon',
    description: 'Completed any quiz challenge in Timed Mode',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFF9800),
  ),
  BadgeDefinition(
    id: 'streak_starter',
    name: 'Streak Starter',
    description: 'Achieve a 2-day daily streak',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF5722),
  ),
  BadgeDefinition(
    id: 'streak_master',
    name: 'Streak Master',
    description: 'Achieve a 5-day daily streak',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFE91E63),
  ),
  BadgeDefinition(
    id: 'streak_legend',
    name: 'Streak Legend',
    description: 'Achieve a 10-day daily streak',
    icon: Icons.brightness_high_rounded,
    color: Color(0xFF9C27B0),
  ),
  BadgeDefinition(
    id: 'consistent_player',
    name: 'Steady Hand',
    description: 'Answered 50 questions in total',
    icon: Icons.psychology_rounded,
    color: Color(0xFF00BCD4),
  ),
  BadgeDefinition(
    id: 'quiz_champion',
    name: 'Quiz Champion',
    description: 'Answered 100 questions in total',
    icon: Icons.emoji_events_rounded,
    color: Color(0xFF3F51B5),
  ),
  BadgeDefinition(
    id: 'grand_master',
    name: 'Grand Master',
    description: 'Answered 250 questions in total',
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFF2196F3),
  ),
  BadgeDefinition(
    id: 'high_scorer',
    name: 'High Scorer',
    description: 'Earned a total score of 500 points',
    icon: Icons.trending_up_rounded,
    color: Color(0xFF4CAF50),
  ),
  BadgeDefinition(
    id: 'elite_scorer',
    name: 'Elite Scorer',
    description: 'Earned a total score of 1000 points',
    icon: Icons.military_tech_rounded,
    color: Color(0xFFFFC107),
  ),
  BadgeDefinition(
    id: 'centurion',
    name: 'Centurion',
    description: 'Earned a total score of 2000 points',
    icon: Icons.shield_rounded,
    color: Color(0xFFE040FB),
  ),
  BadgeDefinition(
    id: 'arch_initiate',
    name: 'Arch Initiate',
    description: 'Earned 50 points in Computer Architecture',
    icon: Icons.memory_rounded,
    color: Color(0xFF8D6E63),
  ),
  BadgeDefinition(
    id: 'arch_expert',
    name: 'Arch Expert',
    description: 'Earned 200 points in Computer Architecture',
    icon: Icons.developer_board_rounded,
    color: Color(0xFF5D4037),
  ),
  BadgeDefinition(
    id: 'net_initiate',
    name: 'Net Initiate',
    description: 'Earned 50 points in Computer Networking',
    icon: Icons.router_rounded,
    color: Color(0xFF4DB6AC),
  ),
  BadgeDefinition(
    id: 'net_expert',
    name: 'Net Expert',
    description: 'Earned 200 points in Computer Networking',
    icon: Icons.lan_rounded,
    color: Color(0xFF00796B),
  ),
  BadgeDefinition(
    id: 'se_initiate',
    name: 'SE Initiate',
    description: 'Earned 50 points in Software Engineering',
    icon: Icons.laptop_mac_rounded,
    color: Color(0xFF90A4AE),
  ),
  BadgeDefinition(
    id: 'se_expert',
    name: 'SE Expert',
    description: 'Earned 200 points in Software Engineering',
    icon: Icons.terminal_rounded,
    color: Color(0xFF37474F),
  ),
  BadgeDefinition(
    id: 'sharp_shooter',
    name: 'Sharp Shooter',
    description: 'Scored at least 8/10 correct answers in a single quiz',
    icon: Icons.gps_fixed_rounded,
    color: Color(0xFF00E676),
  ),
  BadgeDefinition(
    id: 'polymath',
    name: 'Polymath',
    description: 'Earned points in all three core subject categories',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF0091EA),
  ),
];
