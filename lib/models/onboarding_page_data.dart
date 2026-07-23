import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Welcome to Gamified Quiz!',
      description:
          'Your gamified Computer Science learning companion. Test your knowledge, earn XP, and climb the ranks.',
      icon: Icons.school_rounded,
    ),
    OnboardingPageData(
      title: 'Dashboard',
      description:
          'Track your level, XP progress, streaks, and accuracy stats all in one place.',
      icon: Icons.dashboard_rounded,
    ),
    OnboardingPageData(
      title: 'Choose Your Quest',
      description:
          'Pick from Computer Architecture, Software Engineering, or Networking quizzes and play timed or untimed.',
      icon: Icons.extension_rounded,
    ),
    OnboardingPageData(
      title: 'Leaderboard',
      description:
          'See where you rank against other players. Filter by category and compete for the top spot.',
      icon: Icons.emoji_events_rounded,
    ),
    OnboardingPageData(
      title: 'Power-Up Shop',
      description:
          'Spend your earned coins on shields, skips, and time pauses to gain an edge in quizzes.',
      icon: Icons.store_rounded,
    ),
    OnboardingPageData(
      title: 'Your Profile & Badges',
      description:
          'Customize your avatar, showcase earned badges, view analytics, and manage your settings.',
      icon: Icons.person_rounded,
    ),
    OnboardingPageData(
      title: "You're All Set!",
      description: 'Jump in and start your first quest. Knowledge awaits!',
      icon: Icons.rocket_launch_rounded,
    ),
  ];
}
