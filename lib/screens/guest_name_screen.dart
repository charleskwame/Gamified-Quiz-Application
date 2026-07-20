import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/guest_user.dart';
import '../services/local_progress_service.dart';
import '../widgets/home/particle_background.dart';
import 'auth_screen.dart';

class GuestNameScreen extends StatefulWidget {
  final VoidCallback? onSetupComplete;
  const GuestNameScreen({super.key, this.onSetupComplete});

  @override
  State<GuestNameScreen> createState() => _GuestNameScreenState();
}

class _GuestNameScreenState extends State<GuestNameScreen> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final uuid = const Uuid().v4();
      final guest = GuestUser(
        id: uuid,
        username: username,
        createdAt: DateTime.now(),
      );

      await LocalProgressService.saveGuestUser(guest);
      if (mounted) {
        if (widget.onSetupComplete != null) {
          widget.onSetupComplete!();
        } else {
          Navigator.pop(context, guest);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save guest profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ParticleBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  elevation: 4,
                  color: const Color(0xFFECF8F8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFF003F91), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 64,
                            color: Color(0xFF003F91),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Create Guest Username',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF003F91),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Play challenges offline and track progress locally.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF003F91).withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Color(0xFF003F91)),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(color: Color(0xFF003F91)),
                              prefixIcon: const Icon(Icons.person, color: Color(0xFF003F91)),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF003F91)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF003F91), width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.redAccent),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.redAccent),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter a username';
                              }
                              if (val.trim().length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF003F91),
                                foregroundColor: const Color(0xFFFBFBFB),
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
                                        valueColor: AlwaysStoppedAnimation(Color(0xFFFBFBFB)),
                                      ),
                                    )
                                  : const Text('Continue as Guest'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AuthScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFECF8F8),
                                foregroundColor: const Color(0xFF003F91),
                                side: const BorderSide(color: Color(0xFF003F91), width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Create an Account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
