import 'package:flutter/material.dart';
import '../screens/quiz_home_screen.dart';
import '../screens/rankings_page.dart';
import '../screens/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: NavigationBar(
        height: 65,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Rankings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
