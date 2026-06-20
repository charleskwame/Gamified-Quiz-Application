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
      // Existing 20 Badges
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

      // New 30 Badges
      // Streak Badges
      case 'streak_enthusiast':
        return streakNumber >= 3;
      case 'streak_week':
        return streakNumber >= 7;
      case 'streak_fortnight':
        return streakNumber >= 15;
      case 'streak_month':
        return streakNumber >= 30;

      // Score Milestones
      case 'score_100':
        return score >= 100;
      case 'score_300':
        return score >= 300;
      case 'score_800':
        return score >= 800;
      case 'score_1500':
        return score >= 1500;
      case 'score_3000':
        return score >= 3000;
      case 'score_5000':
        return score >= 5000;

      // Questions Answered Milestones
      case 'questions_answered_5':
        return questionsAnswered >= 5;
      case 'questions_answered_25':
        return questionsAnswered >= 25;
      case 'questions_answered_75':
        return questionsAnswered >= 75;
      case 'questions_answered_150':
        return questionsAnswered >= 150;
      case 'questions_answered_500':
        return questionsAnswered >= 500;

      // Correct Answer Milestones
      case 'correct_5':
        return questionsCorrect >= 5;
      case 'correct_20':
        return questionsCorrect >= 20;
      case 'correct_50':
        return questionsCorrect >= 50;
      case 'correct_100':
        return questionsCorrect >= 100;
      case 'correct_300':
        return questionsCorrect >= 300;

      // Category Points Milestones
      case 'arch_apprentice':
        return computerArchitecturePoints >= 10;
      case 'arch_specialist':
        return computerArchitecturePoints >= 100;
      case 'arch_guru':
        return computerArchitecturePoints >= 400;

      case 'net_apprentice':
        return computerNetworkingPoints >= 10;
      case 'net_specialist':
        return computerNetworkingPoints >= 100;
      case 'net_guru':
        return computerNetworkingPoints >= 400;

      case 'se_apprentice':
        return softwareEngineeringPoints >= 10;
      case 'se_specialist':
        return softwareEngineeringPoints >= 100;
      case 'se_guru':
        return softwareEngineeringPoints >= 400;

      // Special Challenge Milestone
      case 'speedy_genius':
        return latestCorrect == 10 && isTimed;

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

  // New Streak Badges
  BadgeDefinition(
    id: 'streak_enthusiast',
    name: 'Streak Enthusiast',
    description: 'Achieve a 3-day daily streak',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF9800),
  ),
  BadgeDefinition(
    id: 'streak_week',
    name: 'Week of Fire',
    description: 'Achieve a 7-day daily streak',
    icon: Icons.whatshot_rounded,
    color: Color(0xFFFFC107),
  ),
  BadgeDefinition(
    id: 'streak_fortnight',
    name: 'Fortnight Flame',
    description: 'Achieve a 15-day daily streak',
    icon: Icons.filter_hdr_rounded,
    color: Color(0xFFFF5722),
  ),
  BadgeDefinition(
    id: 'streak_month',
    name: 'Monthly Champion',
    description: 'Achieve a 30-day daily streak',
    icon: Icons.military_tech_rounded,
    color: Color(0xFFE91E63),
  ),

  // New Score Milestones
  BadgeDefinition(
    id: 'score_100',
    name: 'Bronze Star',
    description: 'Earned a total score of 100 points',
    icon: Icons.looks_one_rounded,
    color: Color(0xFF8D6E63),
  ),
  BadgeDefinition(
    id: 'score_300',
    name: 'Silver Star',
    description: 'Earned a total score of 300 points',
    icon: Icons.looks_two_rounded,
    color: Color(0xFFB0BEC5),
  ),
  BadgeDefinition(
    id: 'score_800',
    name: 'Gold Star',
    description: 'Earned a total score of 800 points',
    icon: Icons.looks_3_rounded,
    color: Color(0xFFFFD54F),
  ),
  BadgeDefinition(
    id: 'score_1500',
    name: 'Vanguard',
    description: 'Earned a total score of 1500 points',
    icon: Icons.shield_outlined,
    color: Color(0xFF3F51B5),
  ),
  BadgeDefinition(
    id: 'score_3000',
    name: 'Grand Champion',
    description: 'Earned a total score of 3000 points',
    icon: Icons.stars_rounded,
    color: Color(0xFFFFB300),
  ),
  BadgeDefinition(
    id: 'score_5000',
    name: 'Quiz Legend',
    description: 'Earned a total score of 5000 points',
    icon: Icons.auto_awesome_motion_rounded,
    color: Color(0xFFF44336),
  ),

  // New Questions Answered Milestones
  BadgeDefinition(
    id: 'questions_answered_5',
    name: 'Warm Up',
    description: 'Answered 5 questions in total',
    icon: Icons.play_arrow_rounded,
    color: Color(0xFF8BC34A),
  ),
  BadgeDefinition(
    id: 'questions_answered_25',
    name: 'Apprentice Quizzer',
    description: 'Answered 25 questions in total',
    icon: Icons.school_rounded,
    color: Color(0xFF009688),
  ),
  BadgeDefinition(
    id: 'questions_answered_75',
    name: 'Dedicated Learner',
    description: 'Answered 75 questions in total',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF03A9F4),
  ),
  BadgeDefinition(
    id: 'questions_answered_150',
    name: 'Scholar',
    description: 'Answered 150 questions in total',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF9C27B0),
  ),
  BadgeDefinition(
    id: 'questions_answered_500',
    name: 'Omniscient',
    description: 'Answered 500 questions in total',
    icon: Icons.all_inclusive_rounded,
    color: Color(0xFFFF5722),
  ),

  // New Correct Answer Milestones
  BadgeDefinition(
    id: 'correct_5',
    name: 'First Victories',
    description: 'Answered 5 questions correctly',
    icon: Icons.thumb_up_rounded,
    color: Color(0xFF4CAF50),
  ),
  BadgeDefinition(
    id: 'correct_20',
    name: 'Bullseye',
    description: 'Answered 20 questions correctly',
    icon: Icons.gps_not_fixed_rounded,
    color: Color(0xFF00BCD4),
  ),
  BadgeDefinition(
    id: 'correct_50',
    name: 'Precision Solver',
    description: 'Answered 50 questions correctly',
    icon: Icons.offline_pin_rounded,
    color: Color(0xFF2196F3),
  ),
  BadgeDefinition(
    id: 'correct_100',
    name: 'Master of Precision',
    description: 'Answered 100 questions correctly',
    icon: Icons.verified_rounded,
    color: Color(0xFF3F51B5),
  ),
  BadgeDefinition(
    id: 'correct_300',
    name: 'Laser Focus',
    description: 'Answered 300 questions correctly',
    icon: Icons.track_changes_rounded,
    color: Color(0xFF673AB7),
  ),

  // New Category Points Milestones
  BadgeDefinition(
    id: 'arch_apprentice',
    name: 'Arch Apprentice',
    description: 'Earned 10 points in Computer Architecture',
    icon: Icons.memory_outlined,
    color: Color(0xFFA1887F),
  ),
  BadgeDefinition(
    id: 'arch_specialist',
    name: 'Arch Specialist',
    description: 'Earned 100 points in Computer Architecture',
    icon: Icons.hardware_rounded,
    color: Color(0xFF795548),
  ),
  BadgeDefinition(
    id: 'arch_guru',
    name: 'Arch Guru',
    description: 'Earned 400 points in Computer Architecture',
    icon: Icons.settings_suggest_rounded,
    color: Color(0xFFD84315),
  ),

  BadgeDefinition(
    id: 'net_apprentice',
    name: 'Net Apprentice',
    description: 'Earned 10 points in Computer Networking',
    icon: Icons.settings_ethernet_rounded,
    color: Color(0xFF80DEEA),
  ),
  BadgeDefinition(
    id: 'net_specialist',
    name: 'Net Specialist',
    description: 'Earned 100 points in Computer Networking',
    icon: Icons.podcasts_rounded,
    color: Color(0xFF00ACC1),
  ),
  BadgeDefinition(
    id: 'net_guru',
    name: 'Net Guru',
    description: 'Earned 400 points in Computer Networking',
    icon: Icons.hub_rounded,
    color: Color(0xFF006064),
  ),

  BadgeDefinition(
    id: 'se_apprentice',
    name: 'SE Apprentice',
    description: 'Earned 10 points in Software Engineering',
    icon: Icons.code_rounded,
    color: Color(0xFF90A4AE),
  ),
  BadgeDefinition(
    id: 'se_specialist',
    name: 'SE Specialist',
    description: 'Earned 100 points in Software Engineering',
    icon: Icons.integration_instructions_rounded,
    color: Color(0xFF607D8B),
  ),
  BadgeDefinition(
    id: 'se_guru',
    name: 'SE Guru',
    description: 'Earned 400 points in Software Engineering',
    icon: Icons.architecture_rounded,
    color: Color(0xFF37474F),
  ),

  // New Special Challenge Milestone
  BadgeDefinition(
    id: 'speedy_genius',
    name: 'Speedy Genius',
    description: 'Scored a perfect 10/10 correct answers in Timed Mode',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFF5722),
  ),
];
