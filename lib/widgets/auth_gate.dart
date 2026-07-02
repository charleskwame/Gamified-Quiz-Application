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

  @override
  void dispose() {
    _verificationTimer?.cancel();
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
        // Show loading while Firebase Auth is initializing/restoring session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
            _verificationTimer?.cancel();
            return const MainNavigation();
          } else {
            _startVerificationPolling();
            return EmailVerificationScreen(email: user.email ?? '');
          }
        }

        _verificationTimer?.cancel();

        // No user signed in — show the auth screen
        // Firebase Auth handles session persistence automatically,
        // so on app restart the stream will emit the logged-in user.
        return AuthScreen(
          onBypass: () {
            setState(() {});
          },
        );
      },
    );
  }
}
