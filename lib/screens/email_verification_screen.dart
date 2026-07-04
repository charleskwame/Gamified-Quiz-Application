import 'dart:async';
import 'dart:math' as math;
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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF060B1A),
              Color(0xFF0A0E21),
              Color(0xFF0F1832),
              Color(0xFF141852),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Particle layer
              Positioned.fill(child: _ParticleOverlay()),

              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
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
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8C52FF),
                                Color(0xFFFFD700),
                                Color(0xFF4ADE80),
                                Color(0xFF6366F1),
                              ],
                              stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.2),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0A0E21),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mark_email_read_rounded,
                                size: 48,
                                color: Color(0xFF6366F1),
                              ),
                            ),
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
                          color: Colors.white,
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
                          Text(
                            'We\'ve sent a verification email to',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
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
                                0xFF6366F1,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
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
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
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
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.25),
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
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF4ADE80,
                              ).withValues(alpha: 0.25),
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
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6366F1,
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
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                          onPressed: (_isResending || _resendCooldown > 0)
                              ? null
                              : _resendEmail,
                          icon: _isResending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6366F1),
                                    ),
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 20),
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
                            foregroundColor: const Color(0xFF6366F1),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            disabledForegroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
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
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.08),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
                  ],
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
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
              ),
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
                  color: Colors.white,
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

// ── Particle Overlay ──

class _ParticleOverlay extends StatefulWidget {
  @override
  State<_ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<_ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 1.5 + _random.nextDouble() * 2.5,
          opacity: 0.15 + _random.nextDouble() * 0.25,
          speed: 0.3 + _random.nextDouble() * 0.7,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller,
          ),
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double speed;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Animation<double> progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final t = progress.value * p.speed;

      double y = (p.y - t * 0.08) % 1.0;
      if (y < 0) y += 1.0;
      final x = p.x + math.sin(t * 2.0 + i) * 0.005;

      double fade = 1.0;
      if (y < 0.1) fade = y / 0.1;
      if (y > 0.9) fade = (1.0 - y) / 0.1;

      final opacity = p.opacity * fade;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
