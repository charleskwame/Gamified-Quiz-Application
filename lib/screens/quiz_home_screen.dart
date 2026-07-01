import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/home/analytics_card.dart';
import '../widgets/home/score_dashboard_card.dart';
import '../widgets/home/modern_course_card.dart';
import '../widgets/streak_card_modal.dart';
import 'challenge_select_screen.dart';
import 'analytics_screen.dart';

class QuizHomePage extends StatelessWidget {
  final VoidCallback onNavigateToRanks;

  const QuizHomePage({super.key, required this.onNavigateToRanks});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildHomeContent(
        context: context,
        displayName: 'Guest',
        questionsAnswered: 0,
        accuracyPercent: 0,
        streakNumber: 0,
        totalScore: 0,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        String displayName = user.displayName ?? 'Scholar';
        int questionsAnswered = 0;
        int questionsCorrect = 0;
        int streakNumber = 0;
        int totalScore = 0;
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          questionsAnswered = data['questionsAnswered'] ?? 0;
          questionsCorrect = data['questionsCorrect'] ?? 0;
          streakNumber = data['streakNumber'] ?? 0;
          totalScore = data['score'] ?? 0;
          avatarUrl = data['avatarUrl'] as String?;
        }

        final accuracyPercent = questionsAnswered > 0
            ? ((questionsCorrect / questionsAnswered) * 100).round()
            : 0;

        return _buildHomeContent(
          context: context,
          displayName: displayName,
          questionsAnswered: questionsAnswered,
          accuracyPercent: accuracyPercent,
          streakNumber: streakNumber,
          totalScore: totalScore,
          avatarUrl: avatarUrl,
        );
      },
    );
  }

  Widget _buildHomeContent({
    required BuildContext context,
    required String displayName,
    required int questionsAnswered,
    required int accuracyPercent,
    required int streakNumber,
    required int totalScore,
    String? avatarUrl,
  }) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $displayName!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF121826),
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your quiz journey starts here.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (streakNumber > 0)
                    GestureDetector(
                      onTap: () {
                        StreakCardModal.show(
                          context,
                          streakNumber,
                          avatarUrl: avatarUrl,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF2EC), Color(0xFFFFECEB)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD5D0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF5722,
                              ).withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF5722),
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$streakNumber Completions',
                              style: const TextStyle(
                                color: Color(0xFFFF5722),
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // Dynamic Analytics Dashboard
              Text(
                'Your Activity Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF121826),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: AnalyticsCard(
                      title: 'Attempted',
                      value: '$questionsAnswered',
                      subtitle: 'Questions',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF141053),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnalyticsCard(
                      title: 'Accuracy',
                      value: '$accuracyPercent%',
                      subtitle: 'Correct Rate',
                      icon: Icons.track_changes_rounded,
                      color: const Color(0xFF4CAF50),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ScoreDashboardCard(
                totalScore: totalScore,
                onPressed: onNavigateToRanks,
              ),

              const SizedBox(height: 32),

              Text(
                'Select Subject Category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF121826),
                ),
              ),
              const SizedBox(height: 16),

              ModernCourseCard(
                category: 'Computer Architecture',
                description:
                    'Dive into pipelines, processor architectures, ALU designs, and instruction execution dynamics.',
                icon: Icons.memory_rounded,
                color1: const Color(0xFF8C52FF),
                color2: const Color(0xFF141053),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengeSelectScreen(
                        category: 'Computer Architecture',
                        icon: Icons.memory_rounded,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ModernCourseCard(
                category: 'Software Engineering',
                description:
                    'Master agile methods, object-oriented designs, UML diagrams, requirements patterns, and testing.',
                icon: Icons.terminal_rounded,
                color1: const Color(0xFF37474F),
                color2: const Color(0xFF5A738E),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengeSelectScreen(
                        category: 'Software Engineering',
                        icon: Icons.laptop_mac_rounded,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ModernCourseCard(
                category: 'Computer Networking',
                description:
                    'Explore packets, routing rules, network layers, sockets, HTTP requests, and TCP/UDP connections.',
                icon: Icons.lan_rounded,
                color1: const Color(0xFF0091EA),
                color2: const Color(0xFF00E5FF),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChallengeSelectScreen(
                        category: 'Computer Networking',
                        icon: Icons.router_rounded,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
