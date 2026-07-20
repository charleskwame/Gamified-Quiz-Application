import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_progress_service.dart';
import '../screens/guest_name_screen.dart';
import 'main_navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _initialized = false;
  bool _needsGuestSetup = false;
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final guest = await LocalProgressService.loadGuestUser();
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
    if (mounted) {
      setState(() {
        _needsGuestSetup = false;
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
          if (mounted) {
            setState(() {
              _needsGuestSetup = false;
            });
          }
        },
      );
    }

    return const MainNavigation();
  }
}

