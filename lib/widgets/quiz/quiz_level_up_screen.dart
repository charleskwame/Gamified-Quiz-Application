import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Data model for level-up information
class LevelUpData {
  final int oldLevel;
  final int newLevel;
  final int totalScore;
  final String? avatarUrl;
  final String displayName;

  const LevelUpData({
    required this.oldLevel,
    required this.newLevel,
    required this.totalScore,
    this.avatarUrl,
    required this.displayName,
  });

  int get xpInCurrentLevel => totalScore % 100;
  double get xpProgress => xpInCurrentLevel / 100.0;
  int get xpToNextLevel => 100;
}

/// Full-screen level-up celebration with organic particle effects.
class QuizLevelUpScreen extends StatefulWidget {
  final LevelUpData data;

  const QuizLevelUpScreen({super.key, required this.data});

  @override
  State<QuizLevelUpScreen> createState() => _QuizLevelUpScreenState();
}

class _QuizLevelUpScreenState extends State<QuizLevelUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;

  // Phase animations
  late Animation<double> _overlayFade;
  late Animation<double> _badgeScale;
  late Animation<double> _levelCounter;
  late Animation<double> _xpBarWidth;

  // Level counter display
  int _displayedOldLevel = 1;
  int _displayedNewLevel = 1;

  // Particle system
  late List<_Particle> _particles;
  final Random _random = Random();

  // Screenshot
  final GlobalKey _repaintKey = GlobalKey();

  // Phase tracking
  bool _badgeVisible = false;
  bool _levelCounterVisible = false;
  bool _xpBarVisible = false;
  bool _buttonsVisible = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initParticles();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Phase 1: Overlay fade-in (0–0.8s)
    _overlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // Phase 2: Badge scale bounce (0.8–1.6s)
    _badgeScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: 1.15), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.4, curve: Curves.easeOutBack),
          ),
        );

    // Phase 3: Level counter (1.6–2.8s)
    _levelCounter = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 4: XP bar (2.2–3.2s)
    _xpBarWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _mainController.addListener(_onMainAnimationTick);
    _mainController.forward();

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _buttonsVisible = true);
      }
    });
  }

  void _onMainAnimationTick() {
    setState(() {
      // Level counter animation: count up old → new
      final levelPhase = (_levelCounter.value * 100).round() / 100;
      if (levelPhase > 0) {
        final levelDiff = widget.data.newLevel - widget.data.oldLevel;
        _displayedOldLevel = widget.data.oldLevel;
        _displayedNewLevel =
            widget.data.oldLevel +
            (levelDiff * levelPhase).round().clamp(1, widget.data.newLevel);
        _levelCounterVisible = true;
      }

      // Visibility flags for build
      if (_badgeScale.value > 0.01) _badgeVisible = true;
      if (_xpBarWidth.value > 0.01) {
        _xpBarVisible = true;
        _levelCounterVisible = true;
      }
    });
  }

  void _initParticles() {
    _particles = List.generate(60, (_) => _Particle._random(_random));
  }

  @override
  void dispose() {
    _mainController.removeListener(_onMainAnimationTick);
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);

    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temp directory and share
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/level_up_${widget.data.displayName.replaceAll(' ', '_')}.png',
      );
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '🎉 I just reached Level ${widget.data.newLevel} in the Gamified Quiz App!',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111C4A)],
          ),
        ),
        child: Stack(
          children: [
            // Organic particle layer (rendered underneath everything)
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                _updateParticles();
                return CustomPaint(
                  size: Size.infinite,
                  painter: _LevelUpParticlesPainter(
                    particles: _particles,
                    animationPhase: _mainController.value.clamp(0.0, 1.0),
                  ),
                );
              },
            ),

            // Overlay darkener for initial fade-in
            FadeTransition(
              opacity: _overlayFade,
              child: Container(color: Colors.black.withValues(alpha: 0.0)),
            ),

            // Main content wrapped in RepaintBoundary for screenshot
            RepaintBoundary(
              key: _repaintKey,
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Avatar
                        _buildAvatar(),
                        const SizedBox(height: 12),

                        // Player name
                        Text(
                          widget.data.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD1D5DB),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Badge: "LEVEL UP!"
                        if (_badgeVisible)
                          AnimatedBuilder(
                            animation: _badgeScale,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: _badgeScale.value,
                                child: _buildLevelUpBadge(),
                              );
                            },
                          ),

                        const SizedBox(height: 40),

                        // Level counter: LV. OLD → NEW
                        if (_levelCounterVisible) _buildLevelCounter(),

                        const SizedBox(height: 32),

                        // XP Progress bar
                        if (_xpBarVisible) _buildXpBar(),
                        const SizedBox(height: 48),

                        // Buttons
                        if (_buttonsVisible) _buildButtons(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (widget.data.avatarUrl != null && widget.data.avatarUrl!.isNotEmpty) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const SweepGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFF6366F1),
              Color(0xFFF59E0B),
              Color(0xFFFFD700),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: CircleAvatar(
          radius: 56,
          backgroundColor: const Color(0xFF1E2246),
          child: ClipOval(
            child: SvgPicture.network(
              widget.data.avatarUrl!,
              width: 108,
              height: 108,
              placeholderBuilder: (context) => const Icon(
                Icons.person_rounded,
                size: 48,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFF2A2F5A),
      child: const Icon(
        Icons.person_rounded,
        size: 60,
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildLevelUpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Text(
            'LEVEL UP!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E1B4B),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('🎉', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildLevelCounter() {
    return Column(
      children: [
        // Old level
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LV.',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_displayedOldLevel',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),

        // Arrow divider
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            Icons.arrow_downward_rounded,
            size: 32,
            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
          ),
        ),

        // New level (animated count)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LV.',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFF59E0B)],
              ).createShader(bounds),
              child: Text(
                '$_displayedNewLevel',
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: Colors.white, // color overridden by ShaderMask
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXpBar() {
    final xp = widget.data.xpInCurrentLevel;
    final progress = widget.data.xpProgress.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // XP label
          Text(
            '${widget.data.xpInCurrentLevel} / ${widget.data.xpToNextLevel} XP',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 10),

          // XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2F5A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3D4375)),
              ),
              child: FractionallySizedBox(
                widthFactor: _xpBarWidth.value * progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Percentage label
          Text(
            '${(xp / widget.data.xpToNextLevel * 100).round()}% to next level',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Continue button
        SizedBox(
          width: 220,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save to gallery button
        SizedBox(
          width: 220,
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _saveToGallery,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(
              _isSaving ? 'Saving...' : 'Save to Gallery',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD1D5DB),
              side: const BorderSide(color: Color(0xFF3D4375)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Particle System ─────────────────────────────────────────────────────

  void _updateParticles() {
    final dt = 1 / 60;
    for (final p in _particles) {
      // Apply gravity (gentle for organic feel)
      p.vy += 0.05;

      // Apply slight drag
      p.vx *= 0.99;
      p.vy *= 0.99;

      // Update position
      p.x += p.vx * dt * 60;
      p.y += p.vy * dt * 60;

      // Gentle rotation
      p.rotation += p.angularVel * dt;

      // Fade out based on age and main animation phase
      p.age += dt;
      final mainPhase = _mainController.value.clamp(0.0, 1.0);
      if (mainPhase < 0.5) {
        // During burst phase, particles are bright
        p.opacity = (1 - p.age / 8).clamp(0.2, 1.0);
      } else {
        // After burst, ambient float with gentle pulsing
        p.opacity = (0.3 + 0.2 * sin(p.age * 2)).clamp(0.1, 0.5);
      }

      // Wrap particles that go off-screen (for ambient float)
      if (p.x < -50 || p.x > 450) p.vx *= -0.5;
      if (p.y > 950) {
        p.y = -20;
        p.vy = -(2 + _random.nextDouble() * 4);
        p.vx = (_random.nextDouble() - 0.5) * 2;
        p.age = 0;
      }
    }
  }
}

// ─── Particle Model ────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy;
  double size, opacity, rotation, angularVel, age;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.rotation,
    required this.angularVel,
    required this.color,
  }) : age = 0;

  factory _Particle._random(Random r) {
    const colors = [
      Color(0xFFFFD700),
      Color(0xFFF59E0B),
      Color(0xFF6366F1),
      Color(0xFFEC4899),
      Color(0xFFFFFFFF),
      Color(0xFF4ADE80),
    ];
    return _Particle(
      x: r.nextDouble() * 400,
      y: r.nextDouble() * 900,
      vx: (r.nextDouble() - 0.5) * 3,
      vy: -(2 + r.nextDouble() * 5),
      size: 2 + r.nextDouble() * 8,
      opacity: 0.8,
      rotation: r.nextDouble() * 2 * pi,
      angularVel: (r.nextDouble() - 0.5) * 0.05,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

// ─── Particle Painter ──────────────────────────────────────────────────────

class _LevelUpParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationPhase;

  _LevelUpParticlesPainter({
    required this.particles,
    required this.animationPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // If in initial burst phase, spawn a fountain effect
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);

      // Draw different shapes based on position for variety
      final shapeType = (p.x * p.y).round() % 3;
      switch (shapeType) {
        case 0:
          // Circle (confetti dot)
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 1:
          // Star/diamond shape
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 4, 0)
            ..lineTo(0, p.size / 2)
            ..lineTo(-p.size / 4, 0)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 2:
          // Small square
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset.zero,
                width: p.size * 0.7,
                height: p.size * 0.7,
              ),
              Radius.circular(p.size * 0.15),
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }

    // Draw a subtle glow at the center-bottom during burst phase
    if (animationPhase < 0.5) {
      final glowPaint = Paint()
        ..shader =
            RadialGradient(
              colors: [
                const Color(
                  0xFFFFD700,
                ).withValues(alpha: 0.15 * (1 - animationPhase)),
                const Color(0xFFFFD700).withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width / 2, size.height * 0.7),
                radius: 150,
              ),
            );
      canvas.drawCircle(
        Offset(size.width / 2, size.height * 0.7),
        150,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LevelUpParticlesPainter oldDelegate) => true;
}
