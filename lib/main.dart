import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/challenge_select_screen.dart';
import 'models/badge.dart';
import 'screens/earned_badges_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user_rank.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/streak_card_modal.dart';
import 'services/notification_service.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'screens/analytics_screen.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  final prefs = await SharedPreferences.getInstance();
  final notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  if (notificationsEnabled) {
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final lastActiveDate = prefs.getString('last_active_date') ?? '';
    final forceTomorrow = lastActiveDate == todayStr;
    await NotificationService().scheduleDailyStreakReminder(forceTomorrow: forceTomorrow);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gamified Quiz',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111C4A),
          primary: const Color(0xFF111C4A),
          error: const Color(0xFF931716),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF121826),
          centerTitle: false,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111C4A),
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF111C4A)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF111C4A),
            side: const BorderSide(color: Color(0xFF111C4A)),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF121826),
            height: 1.05,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF121826),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF121826),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Color(0xFF4B5565),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _bypassAuth = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          _bypassAuth = false;
          return const MainNavigation();
        }

        if (_bypassAuth) {
          return const MainNavigation();
        }

        return AuthScreen(
          onBypass: () {
            setState(() {
              _bypassAuth = true;
            });
          },
        );
      },
    );
  }
}

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
        onNavigateToRanks: onNavigateToRanks,
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

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          questionsAnswered = data['questionsAnswered'] ?? 0;
          questionsCorrect = data['questionsCorrect'] ?? 0;
          streakNumber = data['streakNumber'] ?? 0;
          totalScore = data['score'] ?? 0;
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
          onNavigateToRanks: onNavigateToRanks,
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
    required VoidCallback onNavigateToRanks,
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
                        StreakCardModal.show(context, streakNumber);
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
                              '$streakNumber Days',
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
                    child: _AnalyticsCard(
                      title: 'Attempted',
                      value: '$questionsAnswered',
                      subtitle: 'Questions',
                      icon: Icons.forum_rounded,
                      color: const Color(0xFF5B5FEF),
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
                    child: _AnalyticsCard(
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
              _ScoreDashboardCard(
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

              _ModernCourseCard(
                category: 'Computer Architecture',
                description:
                    'Dive into pipelines, processor architectures, ALU designs, and instruction execution dynamics.',
                icon: Icons.memory_rounded,
                color1: const Color(0xFF8C52FF),
                color2: const Color(0xFF5B5FEF),
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
              _ModernCourseCard(
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
              _ModernCourseCard(
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

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  String _selectedCategory = 'All';
  bool _descending = true;

  int _getUserPoints(UserRank rank) {
    switch (_selectedCategory) {
      case 'Computer Architecture':
        return rank.computerArchitecturePoints;
      case 'Software Engineering':
        return rank.softwareEngineeringPoints;
      case 'Computer Networking':
        return rank.computerNetworkingPoints;
      default:
        return rank.score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final categories = [
      'All',
      'Computer Architecture',
      'Software Engineering',
      'Computer Networking',
    ];

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<UserRank>>(
          stream: dbService.getRankingsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading rankings: ${snapshot.error}'),
              );
            }

            final rankings = snapshot.data ?? [];

            // Sort rankings based on selected points category and sorting direction
            final sortedRankings = List<UserRank>.from(rankings);
            sortedRankings.sort((a, b) {
              final ptsA = _getUserPoints(a);
              final ptsB = _getUserPoints(b);
              return _descending ? ptsB.compareTo(ptsA) : ptsA.compareTo(ptsB);
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rankings',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See how you compare with others',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF111C4A,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _descending
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: const Color(0xFF111C4A),
                          ),
                          tooltip: _descending
                              ? 'Sort Ascending'
                              : 'Sort Descending',
                          onPressed: () {
                            setState(() {
                              _descending = !_descending;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Horizontal Filter Scroll Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF111C4A),
                                fontSize: 13,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                            selectedColor: const Color(0xFF111C4A),
                            checkmarkColor: Colors.white,
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : const Color(
                                        0xFF111C4A,
                                      ).withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (sortedRankings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE6EAF2)),
                      ),
                      child: const Center(
                        child: Text(
                          'No rankings yet. Start playing to get listed!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedRankings.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rank = sortedRankings[index];
                        final isTopThree = index < 3;
                        final colorsMap = [
                          const Color(0xFFFFD700), // Gold
                          const Color(0xFFC0C0C0), // Silver
                          const Color(0xCD853F3A), // Bronze
                        ];
                        final userPoints = _getUserPoints(rank);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE6EAF2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isTopThree
                                      ? colorsMap[index].withValues(alpha: 0.15)
                                      : const Color(0xFFF4F6FB),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isTopThree
                                      ? Icon(
                                          Icons.emoji_events_rounded,
                                          color: colorsMap[index],
                                          size: 18,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4B5565),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rank.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF121826),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (rank.selectedBadges.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4.0,
                                        runSpacing: 4.0,
                                        children: rank.selectedBadges.map((
                                          badgeId,
                                        ) {
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                              Text(
                                '$userPoints pts',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
    final user = _authService.currentUser;
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _emailController = TextEditingController(text: user?.email ?? '');
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
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final lastActiveDate = prefs.getString('last_active_date') ?? '';
      final forceTomorrow = lastActiveDate == todayStr;
      await NotificationService().scheduleDailyStreakReminder(forceTomorrow: forceTomorrow);
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
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final name = _displayNameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (name.isEmpty) {
        throw Exception('Name cannot be empty.');
      }
      if (email.isEmpty) {
        throw Exception('Email cannot be empty.');
      }

      await _authService.updateProfile(
        displayName: name,
        email: email,
        password: password.isNotEmpty ? password : null,
      );

      setState(() {
        _successMessage = 'Account updated successfully!';
        _passwordController.clear();
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        setState(
          () => _errorMessage =
              'For security reasons, please log out and log back in to change your email or password.',
        );
      } else {
        setState(() => _errorMessage = e.message ?? 'An error occurred.');
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
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

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayName = data['displayName'] ?? displayName;
          email = data['email'] ?? email;
          streakNumber = data['streakNumber'] ?? 0;
          unlockedBadgeIds = List<String>.from(data['badges'] ?? []);
          selectedBadges = List<String>.from(data['selectedBadges'] ?? []);
        }

        return _buildProfileContent(
          context: context,
          user: user,
          displayName: displayName,
          email: email,
          streakNumber: streakNumber,
          unlockedBadgeIds: unlockedBadgeIds,
          selectedBadges: selectedBadges,
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
                      if (user != null)
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
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                            color: const Color(0xFF5B5FEF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Colors.white,
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
                              const SizedBox(height: 6),
                              Text(
                                email,
                                style: Theme.of(context).textTheme.bodyLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                  return _BadgeCard(badge: badge, isUnlocked: isUnlocked);
                },
              ),
              if (user != null) ...[
                const SizedBox(height: 32),
                Text(
                  'Update account information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Success message
                if (_successMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      _successMessage!,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name field
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Leave blank to keep current',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _updateAccountInfo,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
              // Delete Account Button (Only for logged in users)
              if (user != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Delete Account?',
                                  style: TextStyle(
                                    color: Color(0xFF931716),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: const Text(
                                  'Warning: This action is irreversible. Your entire progress, achievements, points, earned badges, and offline saved questions will be permanently deleted from the system.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () async {
                                      Navigator.pop(context); // Close dialog
                                      setState(() {
                                        _isLoading = true;
                                        _errorMessage = null;
                                        _successMessage = null;
                                      });
                                      try {
                                        final uid = user.uid;
                                        // 1. Delete Firestore data & SharedPreferences offline questions
                                        await DatabaseService()
                                            .deleteUserAccount(uid);
                                        // 2. Delete user authenticated account from Firebase Auth
                                        await user.delete();
                                        // 3. Perform logout
                                        await _authService.logOut();
                                      } catch (e) {
                                        setState(() {
                                          _errorMessage =
                                              'Failed to delete account: $e. For security, please log out, log back in, and try again.';
                                        });
                                      } finally {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF931716),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Delete Permanently'),
                                  ),
                                ],
                              ),
                            );
                          },
                    icon: const Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFF931716),
                    ),
                    label: const Text(
                      'Delete Account',
                      style: TextStyle(color: Color(0xFF931716)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF931716)),
                    ),
                  ),
                ),
              ],
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

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE6EAF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08121826),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF121826),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDashboardCard extends StatelessWidget {
  final int totalScore;
  final VoidCallback onPressed;

  const _ScoreDashboardCard({
    required this.totalScore,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFFD700),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CUMULATIVE SCORE',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalScore Points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white30,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernCourseCard extends StatelessWidget {
  final String category;
  final String description;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onPressed;

  const _ModernCourseCard({
    required this.category,
    required this.description,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Play Challenge',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge, required this.isUnlocked});

  final BadgeDefinition badge;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05121826),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked ? badge.icon : Icons.lock_rounded,
                color: isUnlocked ? badge.color : const Color(0xFF6B7280),
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF121826),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
