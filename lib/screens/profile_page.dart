import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/badge.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
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
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
    });
  }

  Future<void> _toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !_notificationsEnabled;
    await prefs.setBool('notifications_enabled', newValue);
    setState(() {
      _notificationsEnabled = newValue;
    });

    if (newValue) {
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      final alreadyScheduled = await NotificationService()
          .isReminderScheduled();
      if (!alreadyScheduled) {
        final todayStr = DateTime.now().toIso8601String().split('T')[0];
        final lastActiveDate = prefs.getString('last_active_date') ?? '';
        final forceTomorrow = lastActiveDate == todayStr;
        await NotificationService().scheduleDailyStreakReminder(
          forceTomorrow: forceTomorrow,
        );
      }
    } else {
      await NotificationService().cancelStreakReminder();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Daily streak notifications turned ON'
                : 'Daily streak notifications turned OFF',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: newValue
              ? const Color(0xFF4CAF50)
              : const Color(0xFF616161),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
                      IconButton(
                        onPressed: _toggleNotifications,
                        icon: Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_rounded,
                        ),
                        color: _notificationsEnabled
                            ? const Color(0xFF111C4A)
                            : Colors.grey,
                      ),
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
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
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

              // Test streak notification
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    NotificationService().showImmediateStreakNotification();
                  },
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    size: 16,
                  ),
                  label: const Text('Test Streak Notification'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
