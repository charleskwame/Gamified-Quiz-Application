import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onBypass;

  const AuthScreen({super.key, this.onBypass});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeSlide;

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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────
  //  Google sign-in
  // ──────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User dismissed the Google account picker — stay on the screen.
        return;
      }
      if (mounted) {
        // AuthGate reacts to the auth-state change and shows the app.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AccountLinkRequiredException catch (e) {
      // An email/password account already exists — offer one-time linking.
      final creds = await _promptForEmailPassword(prefillEmail: e.email);
      if (creds != null) {
        await _linkPendingGoogle(
          email: creds.email,
          password: creds.password,
          pendingCredential: e.pendingCredential,
        );
      }
    } on GoogleSignInAbortedException {
      // Cancelled — stay on the screen.
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyGoogleError(e));
    } catch (e) {
      setState(() => _errorMessage = _genericError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _linkPendingGoogle({
    required String email,
    required String password,
    required AuthCredential pendingCredential,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.linkPendingGoogleAccount(
        email: email,
        password: password,
        pendingCredential: pendingCredential,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyEmailError(e));
    } catch (e) {
      setState(() => _errorMessage = _genericError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Explicit path: sign in with an existing email/password account and link a
  /// Google account to it.
  Future<void> _linkExistingAccount() async {
    final creds = await _promptForEmailPassword();
    if (creds == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.linkGoogleToExistingAccount(
        email: creds.email,
        password: creds.password,
      );
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on GoogleSignInAbortedException {
      setState(() => _errorMessage = 'Google linking was cancelled.');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyEmailError(e));
    } catch (e) {
      setState(() => _errorMessage = _genericError(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ──────────────────────────────────────────────
  //  Email/password dialog (one-time migration)
  // ──────────────────────────────────────────────

  Future<({String email, String password})?> _promptForEmailPassword({
    String? prefillEmail,
  }) async {
    final emailController = TextEditingController(text: prefillEmail ?? '');
    final passwordController = TextEditingController();
    String? localError;

    final result = await showDialog<({String email, String password})>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Link Your Google Account',
                style: TextStyle(
                  color: Color(0xFF003F91),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    prefillEmail == null
                        ? 'Sign in once with your existing email and password to link your Google account. You’ll use Google to sign in from now on.'
                        : 'An account with this email already exists. Sign in once with your existing password to link your Google account.',
                    style: const TextStyle(
                      color: Color(0xFF003F91),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    enabled: prefillEmail == null,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFF003F91),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(
                        color: Color(0xFF003F91),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_rounded,
                        color: Color(0xFF003F91),
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
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: const TextStyle(
                      color: Color(0xFF003F91),
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(
                        color: Color(0xFF003F91),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF003F91),
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
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      localError!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF003F91)),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final password = passwordController.text;
                    if (prefillEmail == null && !_isValidEmail(email)) {
                      setDialogState(() {
                        localError = 'Please enter a valid email address.';
                      });
                      return;
                    }
                    if (password.isEmpty) {
                      setDialogState(() {
                        localError = 'Password is required.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, (
                      email: email,
                      password: password,
                    ));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF003F91),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Link Account'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
    return result;
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String _friendlyGoogleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Unable to connect. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is currently disabled. Please contact support.';
      case 'invalid-credential':
        return 'Google sign-in failed. Please try again or use another account.';
      default:
        return 'Google sign-in failed (${e.code}). Please try again or contact support if the issue persists.';
    }
  }

  String _friendlyEmailError(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., name@example.com).';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'credential-already-in-use':
        return 'This Google account is already linked to another account. Please use a different Google account.';
      case 'network-request-failed':
        return 'Unable to connect. Please check your internet connection and try again.';
      default:
        return 'Something went wrong (${e.code}). Please try again.';
    }
  }

  String _genericError(Object e) {
    final errorMsg = e.toString().replaceFirst('Exception: ', '');
    return errorMsg.isNotEmpty
        ? errorMsg
        : 'A network or connection error occurred. Please check your internet and try again.';
  }

  // ──────────────────────────────────────────────
  //  UI
  // ──────────────────────────────────────────────

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
                                  const Text(
                                    'Start Your Quest',
                                    style: TextStyle(
                                      color: Color(0xFF003F91),
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Sign in with Google to begin your learning journey',
                                    style: TextStyle(
                                      color: Color(0xFF003F91),
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Google sign-in card
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
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

                                    // Google button
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _signInWithGoogle,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF003F91,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFB0C4DE),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        icon: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF003F91)),
                                                ),
                                              )
                                            : const _GoogleLogo(size: 22),
                                        label: Text(
                                          _isLoading
                                              ? 'Signing in…'
                                              : 'Continue with Google',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Divider
                                    const Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Color(0xFFB0C4DE),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'or',
                                            style: TextStyle(
                                              color: Color(0xFF003F91),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Color(0xFFB0C4DE),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Link existing account
                                    TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _linkExistingAccount,
                                      child: const Text(
                                        'Sign in with email to link an existing account',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF003F91),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
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
}

// ── Google "G" logo (dependency-free) ──

class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
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
