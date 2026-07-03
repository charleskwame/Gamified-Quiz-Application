import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/quiz_home_screen.dart';
import '../screens/rankings_page.dart';
import '../screens/profile_page.dart';
import '../services/auth_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          QuizHomePage(
            onNavigateToRanks: () {
              setState(() => _selectedIndex = 1);
            },
          ),
          const RankingsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2246).withValues(alpha: 0.65),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 68,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.25),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(color: Colors.white, fontSize: 12);
                  }
                  return const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  );
                }),
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.home_rounded,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    selectedIcon: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    selectedIcon: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700),
                    ),
                    label: 'Rankings',
                  ),
                  NavigationDestination(
                    icon: _buildProfileIcon(),
                    selectedIcon: _buildProfileIcon(),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
