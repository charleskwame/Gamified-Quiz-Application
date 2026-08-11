import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_progress_service.dart';
import '../services/onboarding_service.dart';
import '../screens/email_verification_screen.dart';
import '../screens/guest_name_screen.dart';
import '../screens/onboarding_tour_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;
  bool _needsGuestSetup = false;
  bool _requiresVerification = false;
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
    // Show the loading spinner while resolving auth/verification state so the
    // main navigation never flashes for an unverified (or signed-out) user.
    if (mounted) {
      setState(() => _initialized = false);
    }

    final user = FirebaseAuth.instance.currentUser;
    var requiresVerification = false;

    if (user != null) {
      try {
        await user.reload();
        // Verification is evaluated ONLY here (auth-state change / cold start)
        // and only for a signed-in user. Profile updates (e.g. changing your
        // name) never re-evaluate this, so verification status is untouched.
        requiresVerification = !user.emailVerified;
      } catch (_) {
        // Fail closed: if we can't confirm (e.g. offline), require
        // verification. The verification screen's manual check surfaces a
        // friendly connection error.
        requiresVerification = true;
      }
    }

    if (user == null) {
      final guest = await LocalProgressService.loadGuestUser();
      if (guest == null) {
        if (mounted) {
          setState(() {
            _needsGuestSetup = true;
            _requiresVerification = false;
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
        _requiresVerification = requiresVerification;
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

    // A signed-in user who hasn't verified their email must verify before
    // entering the app. Verification is only checked when they tap the button.
    if (_requiresVerification) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return EmailVerificationScreen(
          email: user.email ?? '',
          onVerified: () => _checkStatus(),
        );
      }
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
