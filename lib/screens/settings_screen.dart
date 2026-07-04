import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/avatar_customizer_dialog.dart';
import '../widgets/home/particle_background.dart';
import '../widgets/main_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        email: null,
        password: null,
      );
      setState(() {
        _successMessage = 'Account information updated successfully!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAvatarCustomizer(
    String? currentUrl,
    Map<String, dynamic>? currentDetails,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AvatarCustomizerDialog(
        initialUrl: currentUrl,
        initialDetails: currentDetails,
        onSave: (url, details) async {
          final user = _authService.currentUser;
          if (user != null) {
            final messenger = ScaffoldMessenger.of(context);
            await _dbService.updateAvatar(user.uid, url, details);
            if (mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Avatar saved successfully!'),
                  backgroundColor: Color(0xFF09262A),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Step 1: Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2246),
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Warning: This action is irreversible. Your entire progress, achievements, points, earned badges, and offline saved questions will be permanently deleted from the system.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 2: Password reauthentication dialog
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2246),
              title: const Text(
                'Confirm Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'For security, please enter your password to confirm account deletion.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      errorText: errorText,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final pw = controller.text.trim();
                    if (pw.isEmpty) {
                      setDialogState(() {
                        errorText = 'Password is required';
                      });
                      return;
                    }
                    Navigator.pop(context, pw);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );

    if (password == null || password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.deleteAccount(password: password);
      if (mounted) {
        // Rebuild entire navigation stack so ProfilePage recreates with null user
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'requires-recent-login':
          message =
              'This operation requires a recent login. Please log out, log back in, and try again.';
          break;
        case 'user-not-found':
          message = 'User account no longer exists.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please wait a moment and try again.';
          break;
        default:
          message = e.message ?? 'Failed to delete account.';
      }
      setState(() {
        _errorMessage = message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete account: $e. Please try again later.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to edit settings.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? avatarUrl;
        Map<String, dynamic>? avatarDetails;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          avatarUrl = data['avatarUrl'];
          if (data['avatarDetails'] != null) {
            avatarDetails = Map<String, dynamic>.from(data['avatarDetails']);
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: ParticleBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Back Button + Title ──
                    _StaggeredFadeSlide(index: 0, child: _buildHeader()),

                    const SizedBox(height: 24),

                    // ── Avatar Section ──
                    _StaggeredFadeSlide(
                      index: 1,
                      child: _buildAvatarSection(avatarUrl, avatarDetails),
                    ),

                    const SizedBox(height: 32),

                    // ── Update Account Info ──
                    _StaggeredFadeSlide(
                      index: 2,
                      child: _buildAccountInfoSection(),
                    ),

                    const SizedBox(height: 32),

                    // ── Divider ──
                    _StaggeredFadeSlide(
                      index: 5,
                      child: Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Danger Zone ──
                    _StaggeredFadeSlide(index: 6, child: _buildDangerZone()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  //  Header
  // ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Avatar Section
  // ──────────────────────────────────────────────

  Widget _buildAvatarSection(
    String? avatarUrl,
    Map<String, dynamic>? avatarDetails,
  ) {
    return Center(
      child: Column(
        children: [
          // Glowing avatar ring matching PlayerHeader style
          _buildGlowingAvatar(avatarUrl),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openAvatarCustomizer(avatarUrl, avatarDetails),
            icon: const Icon(
              Icons.face_retouching_natural_rounded,
              size: 18,
              color: Colors.white70,
            ),
            label: const Text(
              'Customize Avatar',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingAvatar(String? avatarUrl) {
    return Container(
      width: 110,
      height: 110,
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
            color: const Color(0xFF6366F1).withValues(alpha: 0.06),
            blurRadius: 4,
            spreadRadius: 0,
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
          child: ClipOval(
            child: avatarUrl != null && avatarUrl.isNotEmpty
                ? SvgPicture.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => const Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: Colors.white70,
                  ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Account Info Section
  // ──────────────────────────────────────────────

  Widget _buildAccountInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Account Info',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),

        if (_errorMessage != null) ...[
          _buildStatusBanner(_errorMessage!, const Color(0xFFEF4444)),
          const SizedBox(height: 16),
        ],

        if (_successMessage != null) ...[
          _buildStatusBanner(_successMessage!, const Color(0xFF4ADE80)),
          const SizedBox(height: 16),
        ],

        // Name field
        TextField(
          controller: _displayNameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            hintText: 'Enter your full name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8C52FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FilledButton(
              onPressed: _isLoading ? null : _updateAccountInfo,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(String message, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            accentColor == const Color(0xFF4ADE80)
                ? Icons.check_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: 20,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Danger Zone
  // ──────────────────────────────────────────────

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Danger Zone',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _deleteAccount,
            icon: const Icon(
              Icons.delete_forever_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            label: const Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This action cannot be undone. All your data will be permanently removed.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Staggered Fade-Slide — matching app-wide entrance animation
// ═══════════════════════════════════════════════════════════════

class _StaggeredFadeSlide extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggeredFadeSlide({required this.index, required this.child});

  @override
  State<_StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<_StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final startDelay = Duration(milliseconds: 100 * widget.index);
    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    Future.delayed(startDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}
