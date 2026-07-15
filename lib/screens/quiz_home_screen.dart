import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/level_system.dart';
import '../widgets/home/player_header.dart';
import '../widgets/home/game_stat_panel.dart';
import '../widgets/home/xp_vault_card.dart';
import '../widgets/home/quest_card.dart';
import '../widgets/home/leaderboard_carousel.dart';
import '../widgets/levels_overview_modal.dart';
import '../widgets/streak_card_modal.dart';
import 'challenge_select_screen.dart';

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
    final level = LevelSystem.getLevelNumber(totalScore);
    final xpProgress = LevelSystem.getXpProgress(totalScore);

    return SafeArea(
      child: _buildScrollContent(
        context: context,
        displayName: displayName,
        questionsAnswered: questionsAnswered,
        accuracyPercent: accuracyPercent,
        streakNumber: streakNumber,
        totalScore: totalScore,
        level: level,
        xpProgress: xpProgress,
        avatarUrl: avatarUrl,
      ),
    );
  }

  Widget _buildScrollContent({
    required BuildContext context,
    required String displayName,
    required int questionsAnswered,
    required int accuracyPercent,
    required int streakNumber,
    required int totalScore,
    required int level,
    required double xpProgress,
    String? avatarUrl,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combined Player Header + Stats Panel (white bg, blue border, blue divider)
          _buildAnimatedSection(
            index: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF003F91), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerHeader(
                    displayName: displayName,
                    totalScore: totalScore,
                    streakNumber: streakNumber,
                    level: level,
                    xpProgress: xpProgress,
                    avatarUrl: avatarUrl,
                    levelName: LevelSystem.getLevelName(totalScore),
                    onStreakTap: () {
                      StreakCardModal.show(
                        context,
                        streakNumber,
                        avatarUrl: avatarUrl,
                      );
                    },
                    onLevelTap: () {
                      LevelsOverviewModal.show(
                        context: context,
                        totalScore: totalScore,
                        avatarUrl: avatarUrl,
                        displayName: displayName,
                      );
                    },
                  ),
                  Container(height: 1.5, color: const Color(0xFF003F91)),
                  GameStatPanel(
                    questionsAnswered: questionsAnswered,
                    accuracyPercent: accuracyPercent,
                    streakNumber: streakNumber,
                    totalScore: totalScore,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Section 3: Leaderboard carousel
          _buildAnimatedSection(index: 2, child: const LeaderboardCarousel()),

          const SizedBox(height: 20),

          // Section 4: XP Vault
          _buildAnimatedSection(
            index: 3,
            child: XpVaultCard(
              totalScore: totalScore,
              onPressed: onNavigateToRanks,
            ),
          ),

          const SizedBox(height: 32),

          // Section 5: Quests header
          _buildAnimatedSection(
            index: 4,
            child: Text(
              'Available Quests',
              style: const TextStyle(
                color: Color(0xFF003F91),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 6: Quest cards
          _buildAnimatedSection(
            index: 5,
            child: QuestCard(
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
          ),

          const SizedBox(height: 16),

          _buildAnimatedSection(
            index: 6,
            child: QuestCard(
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
          ),

          const SizedBox(height: 16),

          _buildAnimatedSection(
            index: 7,
            child: QuestCard(
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
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Wraps content in a staggered slide-up animation
  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return _StaggeredFadeSlide(index: index, child: child);
  }
}

class _StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({required this.index, required this.child});

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final startDelay = Duration(milliseconds: 100 * widget.index);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    Future.delayed(startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}
