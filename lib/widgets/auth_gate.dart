import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/guest_account_store.dart';
import '../services/onboarding_service.dart';
import '../screens/guest_name_screen.dart';
import '../screens/onboarding_tour_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Ensures the streak (sessions completed) is backfilled from rank history
  // only once per app launch, avoiding repeated count queries.
  static bool _streakSyncedThisLaunch = false;

  bool _initialized = false;
  bool _needsGuestSetup = false;
  bool _showOnboarding = false;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    // Show the loading spinner while resolving auth state so the main
    // navigation never flashes for a signed-out user.
    if (mounted) {
      setState(() => _initialized = false);
    }

    final user = FirebaseAuth.instance.currentUser;

    // One-time backfill: make streakNumber (sessions completed) match the
    // user's rank history count so existing history is counted.
    if (user != null && !_streakSyncedThisLaunch) {
      _streakSyncedThisLaunch = true;
      unawaited(DatabaseService().syncStreakFromRankHistory(user.uid));
    }

    if (user == null) {
      final guest = await GuestAccountStore.instance.load();
      if (guest == null) {
        if (mounted) {
          setState(() {
            _needsGuestSetup = true;
            _initialized = true;
          });
        }
        return;
      }
    }

    // Check if the onboarding tour is required
    final showTour = await OnboardingService.isFirstLaunch();

    if (mounted) {
      setState(() {
        _needsGuestSetup = false;
        _showOnboarding = showTour;
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsGuestSetup) {
      return GuestNameScreen(
        onSetupComplete: () {
          _checkStatus();
        },
      );
    }

    if (_showOnboarding) {
      return OnboardingTourScreen(
        onComplete: () async {
          await OnboardingService.markTourCompleted();
          if (mounted) {
            setState(() {
              _showOnboarding = false;
            });
          }
        },
      );
    }

    return const MainNavigation();
  }
}
