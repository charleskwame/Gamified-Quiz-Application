import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../screens/quiz_home_screen.dart';
import '../screens/rankings_page.dart';
import '../screens/shop_screen.dart';
import '../screens/profile_page.dart';
import '../services/auth_service.dart';
import '../services/update_check_service.dart';
import 'home/particle_background.dart';
import 'update_app_dialog.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  /// Set to false to temporarily hide the bottom navigation bar.
  /// For debugging purposes only remove after use
  static bool showNavBar = true;

  /// Guards the update check so it only runs once per app launch.
  static bool _updateCheckTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (_updateCheckTriggered || !mounted) return;
    _updateCheckTriggered = true;

    final info = await UpdateCheckService().checkForUpdate();
    if (info == null || !mounted) return;

    UpdateAppDialog.show(context, info);
  }

  Widget _buildProfileIcon() {
    final user = _authService.currentUser;
    if (user == null) {
      return const Icon(Icons.person_rounded);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? avatarUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          avatarUrl = data['avatarUrl'] as String?;
        }

        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SvgPicture.network(
              avatarUrl,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              placeholderBuilder: (context) =>
                  const Icon(Icons.person_rounded, size: 24),
            ),
          );
        }

        return const Icon(Icons.person_rounded);
      },
    );
  }

  Widget _buildNavBar() {
    return Positioned(
      bottom: 16,
      left: 24,
      right: 24,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF003F91),
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: GNav(
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() => _selectedIndex = index);
            },
            color: Colors.white.withValues(alpha: 0.55),
            activeColor: const Color(0xFF003F91),
            tabBackgroundColor: const Color(0xFFECF8F8),
            gap: 8,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            tabBorderRadius: 20,
            tabs: [
              GButton(
                icon: Icons.home_rounded,
                text: 'Home',
                iconActiveColor: const Color(0xFF003F91),
                textColor: const Color(0xFF003F91),
              ),
              GButton(
                icon: Icons.emoji_events_rounded,
                text: 'Rankings',
                iconActiveColor: const Color(0xFF003F91),
                textColor: const Color(0xFF003F91),
              ),
              GButton(
                icon: Icons.store_rounded,
                text: 'Shop',
                iconActiveColor: const Color(0xFF003F91),
                textColor: const Color(0xFF003F91),
              ),
              GButton(
                icon: Icons.person_rounded,
                text: 'Profile',
                iconActiveColor: const Color(0xFF003F91),
                textColor: const Color(0xFF003F91),
                leading: _buildProfileIcon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParticleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: [
                QuizHomePage(
                  onNavigateToRanks: () {
                    setState(() => _selectedIndex = 1);
                  },
                ),
                const RankingsPage(),
                const ShopScreen(),
                const ProfilePage(),
              ],
            ),
            if (showNavBar) _buildNavBar(),
          ],
        ),
      ),
    );
  }
}
