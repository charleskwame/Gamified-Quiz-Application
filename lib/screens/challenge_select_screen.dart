import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../widgets/home/particle_background.dart';
import 'quiz_play_screen.dart';

class ChallengeSelectScreen extends StatefulWidget {
  final String category;
  final IconData icon;

  const ChallengeSelectScreen({
    super.key,
    required this.category,
    required this.icon,
  });

  @override
  State<ChallengeSelectScreen> createState() => _ChallengeSelectScreenState();
}

class _ChallengeSelectScreenState extends State<ChallengeSelectScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isDownloading = false;
  bool _hasOffline = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _checkOfflineStatus();
  }

  Future<void> _checkOfflineStatus() async {
    final status = await _db.hasOfflineQuestions(widget.category);
    if (mounted) {
      setState(() {
        _hasOffline = status;
      });
    }
  }

  Future<void> _downloadOffline() async {
    setState(() {
      _isDownloading = true;
      _message = null;
    });

    try {
      await _db.downloadQuestionsForOffline(widget.category);
      if (!mounted) return;
      setState(() {
        _hasOffline = true;
        _message = 'Successfully downloaded 50 questions for offline use!';
        _messageIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Failed to download: $e';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  void _startQuiz({required bool isTimed, required bool isOffline}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          category: widget.category,
          isTimed: isTimed,
          isOffline: isOffline,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Back Button ──
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildBackButton(),
                ),

                const SizedBox(height: 8),

                // ── Header Section ──
                _StaggeredFadeSlide(index: 0, child: _buildHeader()),

                const SizedBox(height: 36),

                // ── Normal Mode ──
                _StaggeredFadeSlide(
                  index: 1,
                  child: _ModeCard(
                    title: 'Normal Challenge',
                    description:
                        'Answer quiz questions with no timer limits. Recommended for learning.',
                    icon: Icons.hourglass_disabled_rounded,
                    colors: const [Color(0xFF141053), Color(0xFF2D1B69)],
                    glowColor: const Color(0xFF8C52FF),
                    onTap: () => _startQuiz(isTimed: false, isOffline: false),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Timed Mode ──
                _StaggeredFadeSlide(
                  index: 2,
                  child: _ModeCard(
                    title: 'Timed Challenge',
                    description:
                        '15 seconds per question. Think fast, test your reflexes under pressure!',
                    icon: Icons.timer_rounded,
                    colors: const [Color(0xFFB71C1C), Color(0xFFFF5722)],
                    glowColor: const Color(0xFFFF5722),
                    onTap: () => _startQuiz(isTimed: true, isOffline: false),
                  ),
                ),

                // ── Offline Mode (only if downloaded) ──
                if (_hasOffline) ...[
                  const SizedBox(height: 16),
                  _StaggeredFadeSlide(
                    index: 3,
                    child: _ModeCard(
                      title: 'Play Offline',
                      description:
                          'Play with locally saved questions. No internet connection required.',
                      icon: Icons.wifi_off_rounded,
                      colors: const [Color(0xFF1B5E20), Color(0xFF388E3C)],
                      glowColor: const Color(0xFF4CAF50),
                      onTap: () => _startQuiz(isTimed: false, isOffline: true),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Divider ──
                _StaggeredFadeSlide(
                  index: 4,
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Download Section ──
                if (user != null)
                  _StaggeredFadeSlide(index: 5, child: _buildDownloadSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Header
  // ──────────────────────────────────────────────

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Large category icon
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF141053), Color(0xFF2D1B69)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C52FF).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 52, color: Colors.white),
        ),
        const SizedBox(height: 24),
        // Title
        Text(
          widget.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Subtitle
        Text(
          'Select Challenge Mode',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose how you want to test your skills today.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Download Section
  // ──────────────────────────────────────────────

  Widget _buildDownloadSection() {
    return Column(
      children: [
        if (_message != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color:
                  (_messageIsError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4ADE80))
                      .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    (_messageIsError
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF4ADE80))
                        .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _messageIsError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 20,
                  color: _messageIsError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF4ADE80),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _messageIsError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF4ADE80),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Full-width glass download button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : _downloadOffline,
            icon: _isDownloading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _hasOffline
                          ? const Color(0xFF4ADE80)
                          : Colors.white,
                    ),
                  )
                : Icon(
                    _hasOffline
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_download_rounded,
                    size: 20,
                  ),
            label: Text(
              _isDownloading
                  ? 'Downloading...'
                  : _hasOffline
                  ? 'Update Offline Questions (50 Saved)'
                  : 'Download 50 Questions for Offline Use',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: BorderSide(
                color: _hasOffline
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
              ),
              foregroundColor: _hasOffline
                  ? const Color(0xFF4ADE80)
                  : Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.04),
              disabledForegroundColor: Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Mode Card — RPG Quest-style with gradient, glow, and stagger
// ═══════════════════════════════════════════════════════════════

class _ModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> colors;
  final Color glowColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.colors,
    required this.glowColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PulsingGlow(
      color: glowColor,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: icon + "Enter" badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_esports_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Play',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Pulsing Glow — subtle animated shadow for quest cards
// ═══════════════════════════════════════════════════════════════

class _PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;

  const _PulsingGlow({required this.child, required this.color});

  @override
  State<_PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<_PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
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
        final glowValue = 0.02 + _controller.value * 0.03;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: glowValue),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Staggered Fade-Slide — entrance animation with index offset
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
