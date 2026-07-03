import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../models/badge.dart';
import '../models/rank_history.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/home/badge_card.dart';
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
      return _buildProfileContent(
        context: context,
        user: null,
        displayName: 'Guest User',
        email: 'Sign in to sync progress',
        streakNumber: 0,
        unlockedBadgeIds: [],
        selectedBadges: [],
        avatarUrl: null,
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
        List<String> unlockedBadgeIds = [];
        List<String> selectedBadges = [];
        String? avatarUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          email = data['email'] ?? email;
          streakNumber = data['streakNumber'] ?? 0;
          unlockedBadgeIds = List<String>.from(data['badges'] ?? []);
          selectedBadges = List<String>.from(data['selectedBadges'] ?? []);
          avatarUrl = data['avatarUrl'] as String?;
        }

        return _buildProfileContent(
          context: context,
          user: user,
          displayName: displayName,
          email: email,
          streakNumber: streakNumber,
          unlockedBadgeIds: unlockedBadgeIds,
          selectedBadges: selectedBadges,
          avatarUrl: avatarUrl,
        );
      },
    );
  }

  Widget _buildProfileContent({
    required BuildContext context,
    required User? user,
    required String displayName,
    required String email,
    required int streakNumber,
    required List<String> unlockedBadgeIds,
    required List<String> selectedBadges,
    required String? avatarUrl,
  }) {
    final previewBadges = allBadges.take(4).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null) ...[
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings_rounded),
                          color: const Color(0xFF141053),
                        ),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Log Out'),
                                content: const Text(
                                  'Are you sure you want to log out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      await _authService.logOut();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Text('Log Out'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.logout_rounded),
                          color: const Color(0xFF931716),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFE6EAF2)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F121826),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: const Color(0xFFE6EAF2),
                              width: 1.5,
                            ),
                          ),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: SvgPicture.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholderBuilder: (context) => const Icon(
                                      Icons.person_rounded,
                                      size: 40,
                                      color: Color(0xFF141053),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: Color(0xFF141053),
                                ),
                        ),
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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (streakNumber > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFECEB),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFFFD5D0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_fire_department_rounded,
                                            color: Color(0xFFFF5722),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '$streakNumber',
                                            style: const TextStyle(
                                              color: Color(0xFFFF5722),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (selectedBadges.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 4.0,
                                  children: selectedBadges.map((badgeId) {
                                    final badge = allBadges.firstWhere(
                                      (b) => b.id == badgeId,
                                    );
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badge.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: badge.color.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            badge.icon,
                                            color: badge.color,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            badge.name,
                                            style: TextStyle(
                                              fontSize: 9,
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
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Badges Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Earned Badges (${unlockedBadgeIds.length}/${allBadges.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (user != null)
                    TextButton.icon(
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
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (user == null) ...[
                Text(
                  'Sign in or create an account to start earning badges!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

              const SizedBox(height: 32),

              // Ranking History Section
              if (user != null) ...[
                Text(
                  'Ranking History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<RankHistoryEntry>>(
                  stream: DatabaseService().getRankHistoryStream(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final entries = snapshot.data ?? [];

                    if (entries.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6EAF2)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.leaderboard_rounded,
                              size: 40,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No rank history yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete a quiz to see your rank!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        // Determine rank letter and color
                        late final String rankLetter;
                        late final Color rankColor;
                        late final Color rankBgColor;

                        if (entry.rank == 1) {
                          rankLetter = 'S';
                          rankColor = const Color(0xFFFFD700);
                          rankBgColor = const Color(0xFFFFF8E1);
                        } else if (entry.rank <= 3) {
                          rankLetter = 'A';
                          rankColor = const Color(0xFF4ADE80);
                          rankBgColor = const Color(0xFFE8F9EF);
                        } else if (entry.rank <= 10) {
                          rankLetter = 'B';
                          rankColor = const Color(0xFF6366F1);
                          rankBgColor = const Color(0xFFF0EFFF);
                        } else if (entry.rank <= 50) {
                          rankLetter = 'C';
                          rankColor = const Color(0xFFF59E0B);
                          rankBgColor = const Color(0xFFFFFAE6);
                        } else {
                          rankLetter = 'D';
                          rankColor = const Color(0xFF9CA3AF);
                          rankBgColor = const Color(0xFFF3F4F6);
                        }

                        final dateStr = DateFormat(
                          'MMM d, yyyy, h:mm a',
                        ).format(entry.timestamp);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE6EAF2)),
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
                                    rankLetter,
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
                                        color: Color(0xFF121826),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
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
                ),
                const SizedBox(height: 32),
              ],

              // Login button for guests
              if (user == null)
                SizedBox(
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
