import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/badge.dart';
import '../models/rank_history.dart';
import '../models/level_system.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/home/badge_card.dart';
import '../widgets/home/particle_background.dart';
import '../widgets/main_navigation.dart';
import 'auth_screen.dart';
import 'earned_badges_screen.dart';
import 'settings_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return _buildScaffold(
        context: context,
        user: null,
        displayName: 'Guest User',
        email: 'Sign in to sync progress',
        streakNumber: 0,
        unlockedBadgeIds: [],
        selectedBadges: [],
        avatarUrl: null,
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

        String displayName = user.displayName ?? 'Guest User';
        String email = user.email ?? '';
        int streakNumber = 0;
        int totalScore = 0;
        List<String> unlockedBadgeIds = [];
        List<String> selectedBadges = [];
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          email = data['email'] ?? email;
          streakNumber = data['streakNumber'] ?? 0;
          totalScore = data['score'] ?? 0;
          unlockedBadgeIds = List<String>.from(data['badges'] ?? []);
          selectedBadges = List<String>.from(data['selectedBadges'] ?? []);
          avatarUrl = data['avatarUrl'] as String?;
        }

        return _buildScaffold(
          context: context,
          user: user,
          displayName: displayName,
          email: email,
          streakNumber: streakNumber,
          unlockedBadgeIds: unlockedBadgeIds,
          selectedBadges: selectedBadges,
          avatarUrl: avatarUrl,
          totalScore: totalScore,
        );
      },
    );
  }

  Scaffold _buildScaffold({
    required BuildContext context,
    required User? user,
    required String displayName,
    required String email,
    required int streakNumber,
    required List<String> unlockedBadgeIds,
    required List<String> selectedBadges,
    required String? avatarUrl,
    required int totalScore,
  }) {
    final previewBadges = allBadges.take(4).toList();
    final level = LevelSystem.getLevelNumber(totalScore);
    final xpProgress = LevelSystem.getXpProgress(totalScore);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ParticleBackground(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row ──
                  _StaggeredFadeSlide(index: 0, child: _buildHeaderRow(user)),

                  const SizedBox(height: 20),

                  // ── Profile Card ──
                  _StaggeredFadeSlide(
                    index: 1,
                    child: _buildProfileCard(
                      context: context,
                      displayName: displayName,
                      email: email,
                      streakNumber: streakNumber,
                      selectedBadges: selectedBadges,
                      avatarUrl: avatarUrl,
                      level: level,
                      totalScore: totalScore,
                      xpProgress: xpProgress,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Badges Section ──
                  _StaggeredFadeSlide(
                    index: 2,
                    child: _buildBadgesSectionHeader(
                      context: context,
                      user: user,
                      unlockedBadgeIds: unlockedBadgeIds,
                      selectedBadges: selectedBadges,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (user == null) ...[
                    _StaggeredFadeSlide(
                      index: 3,
                      child: Text(
                        'Sign in or create an account to start earning badges!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _StaggeredFadeSlide(
                    index: 4,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemCount: previewBadges.length,
                      itemBuilder: (context, index) {
                        final badge = previewBadges[index];
                        final isUnlocked = unlockedBadgeIds.contains(badge.id);
                        return BadgeCard(badge: badge, isUnlocked: isUnlocked);
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Ranking History Section ──
                  if (user != null) ...[
                    _StaggeredFadeSlide(
                      index: 5,
                      child: Text(
                        'Ranking History',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _StaggeredFadeSlide(
                      index: 6,
                      child: _buildRankingHistory(user.uid),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ── Login button for guests ──
                  if (user == null)
                    _StaggeredFadeSlide(
                      index: 5,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(),
                              ),
                            );
                            setState(() {});
                          },
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Log In / Sign Up'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header Row (title + action icons)
  // ──────────────────────────────────────────────

  Widget _buildHeaderRow(User? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (user != null) ...[
              _buildIconButton(
                icon: Icons.settings_rounded,
                color: Colors.white70,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              _buildIconButton(
                icon: Icons.logout_rounded,
                color: const Color(0xFFEF4444),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1E2246),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        FilledButton(
                          onPressed: () async {
                            await _authService.logOut();
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const MainNavigation(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 22),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Profile Card — game-style with glow avatar
  // ──────────────────────────────────────────────

  Widget _buildProfileCard({
    required BuildContext context,
    required String displayName,
    required String email,
    required int streakNumber,
    required List<String> selectedBadges,
    required String? avatarUrl,
    required int level,
    required int totalScore,
    required double xpProgress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + info
          Row(
            children: [
              // Avatar with glowing ring
              _buildGlowingAvatar(avatarUrl),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.08),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${LevelSystem.getLevelName(totalScore)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    // XP bar
                    const SizedBox(height: 10),
                    _buildXpBar(xpProgress, totalScore),
                  ],
                ),
              ),
            ],
          ),
          // Streak and selected badges row
          if (streakNumber > 0 || selectedBadges.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (streakNumber > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF5722).withValues(alpha: 0.2),
                      const Color(0xFFFF5722).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF5722),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakNumber',
                      style: const TextStyle(
                        color: Color(0xFFFF5722),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'completion${streakNumber > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedBadges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: selectedBadges.map((badgeId) {
                  final badge = allBadges.firstWhere((b) => b.id == badgeId);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badge.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: badge.color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badge.icon, color: badge.color, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          badge.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: badge.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGlowingAvatar(String? avatarUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8C52FF),
            Color(0xFFFFD700),
            Color(0xFF4ADE80),
            Color(0xFF6366F1),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0A0E21),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? SvgPicture.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_rounded,
                      color: Colors.white70,
                      size: 40,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                    size: 40,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildXpBar(double xpProgress, int totalScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: xpProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4ADE80,
                          ).withValues(alpha: 0.08),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 4),
            Text(
              '$totalScore XP',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${(xpProgress * 100).round()}% to next level',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Badges Section Header
  // ──────────────────────────────────────────────

  Widget _buildBadgesSectionHeader({
    required BuildContext context,
    required User? user,
    required List<String> unlockedBadgeIds,
    required List<String> selectedBadges,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Earned Badges (${unlockedBadgeIds.length}/${allBadges.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (user != null)
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EarnedBadgesScreen(
                      unlockedBadgeIds: unlockedBadgeIds,
                      initialSelectedBadges: selectedBadges,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('See all'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
              ),
            ),
          ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Ranking History
  // ──────────────────────────────────────────────

  Widget _buildRankingHistory(String uid) {
    return StreamBuilder<List<RankHistoryEntry>>(
      stream: DatabaseService().getRankHistoryStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return _buildEmptyRankHistory();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];

            // Determine rank color based on the letter
            late final Color rankColor;
            late final Color rankBgColor;

            switch (entry.rank) {
              case 'S':
                rankColor = const Color(0xFFFFD700);
                rankBgColor = const Color(0xFFFFD700).withValues(alpha: 0.15);
                break;
              case 'A':
                rankColor = const Color(0xFF4ADE80);
                rankBgColor = const Color(0xFF4ADE80).withValues(alpha: 0.15);
                break;
              case 'B':
                rankColor = const Color(0xFF6366F1);
                rankBgColor = const Color(0xFF6366F1).withValues(alpha: 0.15);
                break;
              case 'C':
                rankColor = const Color(0xFFF59E0B);
                rankBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
                break;
              case 'D':
                rankColor = const Color(0xFF94A3B8);
                rankBgColor = const Color(0xFF94A3B8).withValues(alpha: 0.15);
                break;
              default: // E
                rankColor = const Color(0xFF9CA3AF);
                rankBgColor = const Color(0xFF9CA3AF).withValues(alpha: 0.15);
                break;
            }

            final dateStr = DateFormat(
              'MMM d, yyyy, h:mm a',
            ).format(entry.timestamp);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: rankBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        entry.rank,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: rankColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${entry.percentage.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: rankColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyRankHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 40,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            'No rank history yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete a quiz to see your rank!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Staggered Fade-Slide — matching app-wide entrance animation
// ═══════════════════════════════════════════════════════════════

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
