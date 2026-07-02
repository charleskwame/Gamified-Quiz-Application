import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth_screen.dart';
import '../screens/email_verification_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Timer? _verificationTimer;
  Timer? _sessionRestoreTimer;
  bool _sessionResolved = false;

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _sessionRestoreTimer?.cancel();
    super.dispose();
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
        // Show loading while Firebase Auth is initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // If the user is authenticated, handle email verification & navigation
        if (user != null) {
          _sessionRestoreTimer?.cancel();
          _sessionResolved = true;
          if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
            _verificationTimer?.cancel();
            return const MainNavigation();
          } else {
            _startVerificationPolling();
            return EmailVerificationScreen(email: user.email ?? '');
          }
        }

        _verificationTimer?.cancel();

        // If there's no user, double-check: Firebase Auth may still be
        // restoring the session from disk. Check currentUser synchronously
        // first — if it's non-null, the stream will emit it shortly.
        if (FirebaseAuth.instance.currentUser != null && !_sessionResolved) {
          // Session exists but the stream hasn't emitted it yet.
          // Start a short timer to avoid a brief login-screen flash.
          _sessionRestoreTimer ??= Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _sessionResolved = true;
              });
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _sessionResolved = true;

        // No user signed in — show the auth screen
        return AuthScreen(
          onBypass: () {
            setState(() {});
          },
        );
      },
    );
  }
}
