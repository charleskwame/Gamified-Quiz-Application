import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

import '../widgets/main_navigation.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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

  late AnimationController _animController;
  late Animation<double> _fadeSlide;
  late Animation<double> _iconPulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _iconPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    _animController.dispose();
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
        await DatabaseService().updateEmailVerificationStatus(user.uid, true);
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
            await DatabaseService().updateEmailVerificationStatus(
              user.uid,
              true,
            );
          }
          _navigateToApp();
        } else {
          setState(() {
            _errorMessage =
                'Email not verified yet. Please check your inbox and click the verification link.';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'network-request-failed':
            message =
                'Unable to connect. Please check your internet connection and try again.';
            break;
          case 'too-many-requests':
            message =
                'Too many requests. Please wait a moment before trying again.';
            break;
          case 'user-not-found':
            message = 'Your session may have expired. Please log in again.';
            break;
          default:
            message = 'Something went wrong (${e.code}). Please try again.';
            break;
        }
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        setState(
          () => _errorMessage = errorMsg.isNotEmpty
              ? errorMsg
              : 'Failed to check verification status. Please check your connection and try again.',
        );
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
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message;
        switch (e.code) {
          case 'too-many-requests':
            message =
                'Too many resend requests. Please wait ${_resendCooldown > 0 ? _resendCooldown.toString() : "a moment"} before trying again.';
            break;
          case 'network-request-failed':
            message =
                'Unable to connect. Please check your internet connection and try again.';
            break;
          default:
            message =
                'Failed to resend email (${e.code}). Please try again later.';
            break;
        }
        setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceFirst('Exception: ', '');
        setState(
          () => _errorMessage = errorMsg.isNotEmpty
              ? errorMsg
              : 'Failed to resend email. Please check your connection and try again.',
        );
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

  void _navigateToApp() {
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F8),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8F8),
              Color(0xFFE8F4F4),
              Color(0xFFE0F0F0),
              Color(0xFFD8ECEC),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle light decorative pattern
              Positioned.fill(
                child: CustomPaint(painter: _LightPatternPainter()),
              ),

              // Content
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // Animated email icon
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: AnimatedBuilder(
                                animation: _iconPulse,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _iconPulse.value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF003F91,
                                    ).withValues(alpha: 0.08),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF003F91,
                                        ).withValues(alpha: 0.15),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mark_email_read_rounded,
                                    size: 48,
                                    color: Color(0xFF003F91),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Title
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: const Text(
                                'Verify Your Email',
                                style: TextStyle(
                                  color: Color(0xFF003F91),
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Email display
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Column(
                                children: [
                                  const Text(
                                    'We\'ve sent a verification email to',
                                    style: TextStyle(
                                      color: Color(0xFF003F91),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF003F91,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      widget.email,
                                      style: const TextStyle(
                                        color: Color(0xFF003F91),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Instructions card
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF003F91,
                                      ).withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInstructionRow(
                                      Icons.mark_email_read_rounded,
                                      'Open the verification email we sent you',
                                      0,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInstructionRow(
                                      Icons.touch_app_rounded,
                                      'Click the "Verify Email" link in the email',
                                      1,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInstructionRow(
                                      Icons.refresh_rounded,
                                      'Come back here and tap "I\'ve Verified"',
                                      2,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Error message
                            if (_errorMessage != null)
                              FadeTransition(
                                opacity: _fadeSlide,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Success message
                            if (_successMessage != null)
                              FadeTransition(
                                opacity: _fadeSlide,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF4ADE80,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4ADE80,
                                      ).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF4ADE80),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _successMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // "I've Verified" button
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: SizedBox(
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: const Color(0xFF003F91),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF003F91,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: FilledButton.icon(
                                    onPressed: _isChecking || _isVerified
                                        ? null
                                        : _checkVerificationManually,
                                    icon: _isChecking
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            _isVerified
                                                ? Icons.check_circle_rounded
                                                : Icons.verified_rounded,
                                            size: 20,
                                          ),
                                    label: Text(
                                      _isChecking
                                          ? 'Checking...'
                                          : _isVerified
                                          ? 'Verified!'
                                          : 'I\'ve Verified - Continue',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Resend button
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      (_isResending || _resendCooldown > 0)
                                      ? null
                                      : _resendEmail,
                                  icon: _isResending
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF003F91),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          size: 20,
                                        ),
                                  label: Text(
                                    _resendCooldown > 0
                                        ? 'Resend in ${_resendCooldown}s'
                                        : 'Resend Email',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF003F91),
                                    side: const BorderSide(
                                      color: Color(0xFF003F91),
                                      width: 1.5,
                                    ),
                                    disabledForegroundColor: const Color(
                                      0xFF003F91,
                                    ).withValues(alpha: 0.3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Help text
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Text(
                                'Didn\'t receive the email? Check your spam folder or make sure you entered the correct email address.',
                                style: const TextStyle(
                                  color: Color(0xFF003F91),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Divider
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: const Color(
                                        0xFF003F91,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: const Color(
                                          0xFF003F91,
                                        ).withValues(alpha: 0.3),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: const Color(
                                        0xFF003F91,
                                      ).withValues(alpha: 0.12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Log out
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: TextButton.icon(
                                onPressed: _isLoggingOut ? null : _logOut,
                                icon: _isLoggingOut
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFFEF4444),
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                label: Text(
                                  _isLoggingOut
                                      ? 'Logging out...'
                                      : 'Use a different email',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),

                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(IconData icon, String text, int index) {
    return FadeTransition(
      opacity: _fadeSlide,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF003F91),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF003F91),
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Light Pattern Overlay ──

class _LightPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw subtle decorative circles
    paint.color = const Color(0xFF003F91).withValues(alpha: 0.03);

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      120,
      paint,
    );

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 80, paint);

    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 200, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
