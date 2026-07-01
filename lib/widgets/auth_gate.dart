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
  bool _bypassAuth = true;
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
        if (snapshot.connectionState == ConnectionState.waiting) {
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
