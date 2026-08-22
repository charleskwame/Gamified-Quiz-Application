import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/level_system.dart';
import '../../services/sound_service.dart';

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

  String get oldLevelName =>
      LevelSystem.levels[oldLevel >= 1 ? oldLevel - 1 : 0].name;
  String get newLevelName => LevelSystem.getLevelName(totalScore);
  int get xpInCurrentLevel =>
      totalScore - LevelSystem.getLevelByScore(totalScore).xpRequired;
  double get xpProgress => LevelSystem.getXpProgress(totalScore);
  int get xpToNextLevel => LevelSystem.getXpToNextLevel(totalScore);
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
  late AnimationController _particleController;

  // One controller per staggered section (fade+slide-from-bottom)
  late final List<AnimationController> _sectionControllers;
  late final List<Animation<double>> _sectionOpacity;
  late final List<Animation<Offset>> _sectionSlide;

  // XP bar fill animation (driven by section controller[3])
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initParticles();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Build one controller per section: avatar+name, badge, level counter,
    // XP bar, buttons — each 600 ms, delayed by 120 ms * index.
    const sectionCount = 5;
    _sectionControllers = List.generate(
      sectionCount,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _sectionOpacity = _sectionControllers
        .map(
          (c) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: c,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ),
          ),
        )
        .toList();

    _sectionSlide = _sectionControllers
        .map(
          (c) =>
              Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: c,
                  curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
                ),
              ),
        )
        .toList();

    // XP bar fill follows the xp-bar section controller (index 3)
    _xpBarWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _sectionControllers[3],
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Level counter count-up: driven by section controller index 2
    _sectionControllers[2].addListener(_onLevelCounterTick);

    // Kick off each section with a staggered delay
    for (int i = 0; i < sectionCount; i++) {
      Future.delayed(Duration(milliseconds: 120 * i), () {
        if (mounted) _sectionControllers[i].forward();
      });
    }

    // Play the level-up fanfare as the celebration starts.
    SoundService.instance.playLevelUp();
  }

  void _onLevelCounterTick() {
    setState(() {
      final levelPhase = _sectionControllers[2].value.clamp(0.0, 1.0);
      final levelDiff = widget.data.newLevel - widget.data.oldLevel;
      _displayedOldLevel = widget.data.oldLevel;
      _displayedNewLevel =
          widget.data.oldLevel +
          (levelDiff * levelPhase).round().clamp(1, widget.data.newLevel);
    });
  }

  void _initParticles() {
    _particles = List.generate(60, (_) => _Particle._random(_random));
  }

  @override
  void dispose() {
    _sectionControllers[2].removeListener(_onLevelCounterTick);
    for (final c in _sectionControllers) {
      c.dispose();
    }
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
              'I just reached Level ${widget.data.newLevel} in the Gamified Quiz App!',
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
      backgroundColor: const Color(0xFFECF8F8),
      body: Container(
        color: const Color(0xFFECF8F8),
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
                    animationPhase: _particleController.value,
                  ),
                );
              },
            ),

            // Close button (outside RepaintBoundary so it's not in screenshots)
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF8F8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF003F91).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF003F91).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF003F91),
                      size: 24,
                    ),
                    tooltip: 'Close',
                  ),
                ),
              ),
            ),

            // Main content wrapped in RepaintBoundary for screenshot
            RepaintBoundary(
              key: _repaintKey,
              child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),

                                // Section 0: Avatar + player name
                                _FadeSlideSection(
                                  opacity: _sectionOpacity[0],
                                  slide: _sectionSlide[0],
                                  child: Column(
                                    children: [
                                      _buildAvatar(),
                                      const SizedBox(height: 12),
                                      Text(
                                        widget.data.displayName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF003F91),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Section 1: "LEVEL UP!" badge
                                _FadeSlideSection(
                                  opacity: _sectionOpacity[1],
                                  slide: _sectionSlide[1],
                                  child: _buildLevelUpBadge(),
                                ),
                                const SizedBox(height: 10),

                                // Section 2: Level counter (OLD → NEW) + penalty notice
                                _FadeSlideSection(
                                  opacity: _sectionOpacity[2],
                                  slide: _sectionSlide[2],
                                  child: Column(
                                    children: [
                                      _buildLevelCounter(),
                                      if (widget.data.newLevel == 2) ...[
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32.0,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFEF4444,
                                              ).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFEF4444,
                                                ).withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'The penalty system is now in effect from this rank onwards.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFEF4444),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Section 3: XP bar
                                _FadeSlideSection(
                                  opacity: _sectionOpacity[3],
                                  slide: _sectionSlide[3],
                                  child: _buildXpBar(),
                                ),
                                const SizedBox(height: 48),

                                // Section 4: Buttons
                                _FadeSlideSection(
                                  opacity: _sectionOpacity[4],
                                  slide: _sectionSlide[4],
                                  child: _buildButtons(),
                                ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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
            ],
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: CircleAvatar(
          radius: 56,
          backgroundColor: const Color(0xFFE2F0F0),
          child: ClipOval(
            child: SvgPicture.network(
              widget.data.avatarUrl!,
              width: 108,
              height: 108,
              placeholderBuilder: (context) => const Icon(
                Icons.person_rounded,
                size: 48,
                color: Color(0xFF003F91),
              ),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 50,
      backgroundColor: const Color(0xFFE2F0F0),
      child: const Icon(
        Icons.person_rounded,
        size: 50,
        color: Color(0xFF003F91),
      ),
    );
  }

  Widget _buildLevelUpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF003F91), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'lib/assets/icon/party.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFF003F91),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'LEVEL UP!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003F91),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          SvgPicture.asset(
            'lib/assets/icon/party.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFF003F91),
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCounter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF003F91).withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Old level (smaller) with rank name beside the number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LV.',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_displayedOldLevel',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.data.oldLevelName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF).withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          // Arrow connector chip
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF003F91),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),

          // New level (larger) with rank name beside the number
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LV.',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF003F91),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_displayedNewLevel',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF003F91),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.data.newLevelName,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF003F91),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
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
          Text(
            '${widget.data.xpInCurrentLevel} / ${widget.data.xpToNextLevel} XP',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF003F91),
            ),
          ),
          const SizedBox(height: 10),

          // XP progress bar: full-width track, filled up to the
          // percentage of XP toward the next level.
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE2F0F0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF003F91).withValues(alpha: 0.2),
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _xpBarWidth.value * progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF003F91),
                    borderRadius: BorderRadius.circular(12),
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
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003F91).withValues(alpha: 0.6),
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
          width: 300,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            label: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF003F91),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              // elevation: 8,
              // shadowColor: const Color(0xFF003F91).withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Save to gallery button
        SizedBox(
          width: 300,
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
              foregroundColor: const Color(0xFF003F91),
              side: const BorderSide(color: Color(0xFF003F91)),
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

      // Fade out based on age — ambient float with gentle pulsing
      p.age += dt;
      p.opacity = (0.3 + 0.2 * sin(p.age * 2)).clamp(0.1, 0.5);

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
      Color(0xFF003F91),
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

// ═══════════════════════════════════════════════════════════════
//  Fade + Slide-from-bottom — app-wide entrance animation
// ═══════════════════════════════════════════════════════════════

class _FadeSlideSection extends StatelessWidget {
  final Animation<double> opacity;
  final Animation<Offset> slide;
  final Widget child;

  const _FadeSlideSection({
    required this.opacity,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
