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
  Timer? _signedOutGraceTimer;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _authResolved = false;

  @override
  void initState() {
    super.initState();

    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _authResolved = true;
    }

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      _signedOutGraceTimer?.cancel();

      setState(() {
        _user = user;
        _authResolved = user != null;
      });

      if (user == null) {
        _signedOutGraceTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && _user == null) {
            setState(() {
              _authResolved = true;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _signedOutGraceTimer?.cancel();
    _authSubscription?.cancel();
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
    if (!_authResolved) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;

    if (user != null) {
      if (FirebaseAuth.instance.currentUser?.emailVerified == true) {
        _verificationTimer?.cancel();
        return const MainNavigation();
      }

      _startVerificationPolling();
      return EmailVerificationScreen(email: user.email ?? '');
    }

    _verificationTimer?.cancel();

    // No user signed in — show the auth screen.
    return AuthScreen(
      onBypass: () {
        setState(() {
          _authResolved = true;
        });
      },
    );
  }
}
