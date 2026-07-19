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

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final guest = await LocalProgressService.loadGuestUser();
      if (guest == null) {
        setState(() {
          _needsGuestSetup = true;
          _initialized = true;
        });
        return;
      }
    }
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_needsGuestSetup) {
      return GuestNameScreen(
        onSetupComplete: () {
          setState(() {
            _needsGuestSetup = false;
          });
        },
      );
    }

    return const MainNavigation();
  }
}

