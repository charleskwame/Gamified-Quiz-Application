import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _isVerified = false;
  bool _isResending = false;
  bool _isLoggingOut = false;
  String? _errorMessage;
  String? _successMessage;

  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isVerified) {
      _checkVerificationSilently();
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isVerified && mounted) {
        await _checkVerificationSilently();
      }
    });
  }

  Future<void> _checkVerificationSilently() async {
    final verified = await _authService.checkEmailVerification();
    if (verified && mounted) {
      setState(() => _isVerified = true);
      _pollingTimer?.cancel();
      final user = _authService.currentUser;
      if (user != null) {
        await DatabaseService()
            .updateEmailVerificationStatus(user.uid, true);
      }
      _navigateToApp();
    }
  }

  Future<void> _checkVerificationManually() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final verified = await _authService.checkEmailVerification();
      if (mounted) {
        if (verified) {
          setState(() => _isVerified = true);
          _pollingTimer?.cancel();
          final user = _authService.currentUser;
          if (user != null) {
            await DatabaseService()
                .updateEmailVerificationStatus(user.uid, true);
          }
          _navigateToApp();
        } else {
          setState(() {
            _errorMessage =
                'Email not verified yet. Please check your inbox and click the verification link.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to check verification status. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.resendVerificationEmail();
      if (mounted) {
        setState(() {
          _successMessage = 'Verification email resent successfully!';
        });
        _startResendCooldown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to resend email. Please try again later.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _startResendCooldown() {
    _resendCooldown = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendCooldown--;
        });
      }
      if (_resendCooldown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> _logOut() async {
    setState(() => _isLoggingOut = true);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    await _authService.logOut();
  }

  // AuthGate's periodic timer handles the actual navigation to MainNavigation
  void _navigateToApp() {
    // Verification is detected — AuthGate will transition within 3 seconds
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Email icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF111C4A).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_rounded,
                  size: 64,
                  color: Color(0xFF111C4A),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF121826),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'We\'ve sent a verification email to',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF4B5565),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111C4A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Instructions card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EAF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructionRow(
                      Icons.mark_email_read_rounded,
                      'Open the verification email we sent you',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionRow(
                      Icons.touch_app_rounded,
                      'Click the "Verify Email" link in the email',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionRow(
                      Icons.refresh_rounded,
                      'Come back here and tap "I\'ve Verified"',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Success message
              if (_successMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // "I've Verified" button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isChecking || _isVerified
                      ? null
                      : _checkVerificationManually,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.verified_rounded, size: 20),
                  label: Text(
                    _isChecking
                        ? 'Checking...'
                        : _isVerified
                            ? 'Verified!'
                            : 'I\'ve Verified - Continue',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              // Resend button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: (_isResending || _resendCooldown > 0)
                      ? null
                      : _resendEmail,
                  icon: _isResending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Email',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFF111C4A)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Help text
              Text(
                'Didn\'t receive the email? Check your spam folder or make sure you entered the correct email address.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),


              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              // Log out
              TextButton.icon(
                onPressed: _isLoggingOut ? null : _logOut,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded,
                        color: Color(0xFF931716)),
                label: Text(
                  _isLoggingOut ? 'Logging out...' : 'Log Out',
                  style: const TextStyle(
                    color: Color(0xFF931716),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF111C4A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF111C4A)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF121826),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
