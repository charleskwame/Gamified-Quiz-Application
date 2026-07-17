import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
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

        // Client-side email validation
        if (!_isValidEmail(email)) {
          setState(
            () => _errorMessage =
                'Please enter a valid email address (e.g., name@example.com).',
          );
          setState(() => _isLoading = false);
          return;
        }

        // Client-side password validation
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

        // After successful sign-up, navigate to email verification screen
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

        // Client-side email validation for login too
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button row
                            if (showBackButton)
                              FadeTransition(
                                opacity: _fadeSlide,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF003F91,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Color(0xFF003F91),
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

                            // Title section
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
                                      color: Color(0xFF003F91),
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
                                    style: const TextStyle(
                                      color: Color(0xFF003F91),
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Form card
                            FadeTransition(
                              opacity: _fadeSlide,
                              child: Container(
                                padding: const EdgeInsets.all(24),
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
                                    // Mode toggle pills
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECF8F8),
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

                                    // Error message
                                    if (_errorMessage != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      const SizedBox(height: 20),
                                    ],

                                    // Display name field (only for sign up)
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

                                    // Email field
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      hint: 'Enter your email',
                                      icon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),

                                    // Password field
                                    _buildTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: 'Enter your password',
                                      icon: Icons.lock_rounded,
                                      isPassword: true,
                                    ),
                                    const SizedBox(height: 28),

                                    // Submit button
                                    SizedBox(
                                      width: double.infinity,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
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

                            // Bottom text
                            FadeTransition(
                              opacity: _toggleSlide,
                              child: Center(
                                child: Text(
                                  _isSignUp
                                      ? 'Already have an account?'
                                      : "Don't have an account?",
                                  style: const TextStyle(
                                    color: Color(0xFF003F91),
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
          color: isSelected ? const Color(0xFF003F91) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF003F91),
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
          style: const TextStyle(color: Color(0xFF003F91), fontSize: 15),
          cursorColor: const Color(0xFF003F91),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(color: Color(0xFF003F91), fontSize: 14),
            hintStyle: TextStyle(
              color: const Color(0xFF003F91).withValues(alpha: 0.3),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF003F91).withValues(alpha: 0.35),
              size: 20,
            ),
            filled: true,
            fillColor: const Color(0xFFECF8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF003F91),
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
