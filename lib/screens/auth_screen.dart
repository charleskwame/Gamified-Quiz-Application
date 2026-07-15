import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:math' as math;
import 'email_verification_screen.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onBypass;

  const AuthScreen({super.key, this.onBypass});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isSignUp = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeSlide;
  late Animation<double> _toggleSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _toggleSlide = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message =
            'Your password is too weak. Use at least 6 characters with a mix of letters, numbers, and symbols.';
        break;
      case 'email-already-in-use':
        message = 'This email is already registered. Try logging in instead.';
        break;
      case 'user-not-found':
        message =
            'No account found with this email address. Double-check your email or sign up for a new account.';
        break;
      case 'wrong-password':
        message =
            'Incorrect password. Please try again or reset your password.';
        break;
      case 'invalid-email':
        message =
            'Please enter a valid email address (e.g., name@example.com).';
        break;
      case 'invalid-credential':
        message =
            'Invalid email or password. Please check your credentials and try again.';
        break;
      case 'user-disabled':
        message =
            'This account has been disabled. Please contact support for assistance.';
        break;
      case 'too-many-requests':
        message =
            'Too many login attempts. Please wait 30 seconds before trying again.';
        break;
      case 'operation-not-allowed':
        message =
            'Email/password sign-in is currently disabled. Please contact support.';
        break;
      case 'network-request-failed':
        message =
            'Unable to connect. Please check your internet connection and try again.';
        break;
      default:
        message =
            'Something went wrong (${e.code}). Please try again or contact support if the issue persists.';
        break;
    }

    setState(() => _errorMessage = message);
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        if (_displayNameController.text.isEmpty) {
          setState(
            () => _errorMessage = 'Please enter your full name to continue.',
          );
          setState(() => _isLoading = false);
          return;
        }

        final email = _emailController.text.trim();
        final password = _passwordController.text;

        if (!_isValidEmail(email)) {
          setState(
            () => _errorMessage =
                'Please enter a valid email address (e.g., name@example.com).',
          );
          setState(() => _isLoading = false);
          return;
        }

        if (password.length < 6) {
          setState(
            () => _errorMessage =
                'Password must be at least 6 characters long for security.',
          );
          setState(() => _isLoading = false);
          return;
        }

        await _authService.signUp(
          email: email,
          password: password,
          displayName: _displayNameController.text.trim(),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email),
            ),
          );
        }
        return;
      } else {
        final email = _emailController.text.trim();

        if (!_isValidEmail(email)) {
          setState(
            () => _errorMessage =
                'Please enter a valid email address (e.g., name@example.com).',
          );
          setState(() => _isLoading = false);
          return;
        }

        await _authService.logIn(
          email: email,
          password: _passwordController.text,
        );
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      setState(
        () => _errorMessage = errorMsg.isNotEmpty
            ? errorMsg
            : 'A network or connection error occurred. Please check your internet and try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final showBackButton = canPop || widget.onBypass != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF121212),
              Color(0xFF1A1A1A),
              Color(0xFF222222),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _ParticleOverlay()),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showBackButton)
                              FadeTransition(
                                opacity: _fadeSlide,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (canPop) {
                                      Navigator.pop(context);
                                    } else if (widget.onBypass != null) {
                                      widget.onBypass!();
                                    }
                                  },
                                ),
                              ),
                            const SizedBox(height: 32),
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Text(
                                    _isSignUp
                                        ? 'Start Your Quest'
                                        : 'Welcome Back',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isSignUp
                                        ? 'Create an account to begin your learning journey'
                                        : 'Log in to continue your adventure',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Container(
                                padding: const EdgeInsets.all(24),
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
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildTogglePill('Sign Up', true),
                                            const SizedBox(width: 4),
                                            _buildTogglePill('Log In', false),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    if (_errorMessage != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF5A3A3A,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF5A3A3A,
                                            ).withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline_rounded,
                                              color: Color(0xFF5A3A3A),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Color(0xFF5A3A3A),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      alignment: Alignment.topCenter,
                                      child: _isSignUp
                                          ? Column(
                                              children: [
                                                _buildTextField(
                                                  controller:
                                                      _displayNameController,
                                                  label: 'Full Name',
                                                  hint: 'Enter your full name',
                                                  icon: Icons.person_rounded,
                                                ),
                                                const SizedBox(height: 16),
                                              ],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'Enter your email',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      icon: Icons.lock_rounded,
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 28),
                                    SizedBox(
                                      width: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF808080),
                                              Color(0xFFB0B0B0),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF808080,
                                              ).withValues(alpha: 0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: FilledButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _authenticate,
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
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : Text(
                                                  _isSignUp
                                                      ? 'Create Account'
                                                      : 'Log In',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _toggleSlide,
                              child: Center(
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account?'
                                      : "Don't have an account?",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
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

  Widget _buildTogglePill(String label, bool isSignUpSelected) {
    final isSelected = _isSignUp == isSignUpSelected;
    return GestureDetector(
      onTap: isSelected ? null : _toggleMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF808080).withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: const Color(0xFF808080),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.35),
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF808080),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        );
      },
    );
  }
}

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
