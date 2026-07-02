import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import '../screens/email_verification_screen.dart';
import '../services/auth_service.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  bool _bypassAuth = true;
  bool _hasPreviousSession = false;
  bool _sessionCheckDone = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _checkPreviousSession();
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  /// Checks secure storage to see if the user was previously logged in
  /// (before a potential app reinstall / data wipe).
  Future<void> _checkPreviousSession() async {
    final hadSession = await _authService.hasPreviousSession();
    if (mounted) {
      setState(() {
        _hasPreviousSession = hadSession;
        // If there was a previous session but Firebase lost it (e.g. after reinstall),
        // do NOT bypass to guest mode — force the auth screen.
        if (hadSession) {
          _bypassAuth = false;
        }
        _sessionCheckDone = true;
      });
    }
  }

  void _startVerificationPolling() {
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.emailVerified) {
          _verificationTimer?.cancel();
          setState(() {}); // Trigger rebuild -> MainNavigation
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while we check the previous session, and while
        // Firebase Auth is still initializing its persisted session.
        if (!_sessionCheckDone ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          _bypassAuth = false;
          if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
            _verificationTimer?.cancel();
            return const MainNavigation();
          } else {
            _startVerificationPolling();
            return EmailVerificationScreen(email: user.email ?? '');
          }
        }

        _verificationTimer?.cancel();

        // Allow guest/bypass only if the user never had a previous session.
        // If they did have one, force them to the login screen.
        if (_bypassAuth && !_hasPreviousSession) {
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
