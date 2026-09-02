import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/settings_service.dart';

/// A subtle animated particle system that creates a floating star/dot effect
/// in the background, giving a modern game-like atmosphere.
class ParticleBackground extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ParticleBackground({
    super.key,
    required this.child,
    this.isActive = true,
  });

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Generate 28 particles with random initial positions
    for (int i = 0; i < 28; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 2.0 + _random.nextDouble() * 3.0,
          opacity: 0.4 + _random.nextDouble() * 0.4,
          speed: 0.3 + _random.nextDouble() * 0.7,
        ),
      );
    }

    // Synchronize initial preference and listen for changes
    SettingsService.particlesEnabledNotifier.addListener(_syncAnimationState);
    SettingsService.isParticlesEnabled().then((_) {
      if (mounted) _syncAnimationState();
    });
    _syncAnimationState();
  }

  void _syncAnimationState() {
    final shouldAnimate =
        widget.isActive && SettingsService.particlesEnabledNotifier.value;
    if (shouldAnimate) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void didUpdateWidget(covariant ParticleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    SettingsService.particlesEnabledNotifier.removeListener(_syncAnimationState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SettingsService.particlesEnabledNotifier,
      builder: (context, particlesEnabled, _) {
        final showParticles = widget.isActive && particlesEnabled;
        return SizedBox.expand(
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFFECF8F8)),
            child: Stack(
              children: [
                // Particle layer (only animated & painted if active and enabled)
                if (showParticles)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Positioned.fill(
                        child: CustomPaint(
                          painter: _ParticlePainter(
                            particles: _particles,
                            progress: _controller,
                          ),
                        ),
                      );
                    },
                  ),
                // Content layer
                widget.child,
              ],
            ),
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

      // Particles drift upward and reset
      double y = (p.y - t * 0.08) % 1.0;
      if (y < 0) y += 1.0;
      final x = p.x + sin(t * 2.0 + i) * 0.005;

      // Fade in/out at edges for smooth appearance/disappearance
      double fade = 1.0;
      if (y < 0.1) fade = y / 0.1;
      if (y > 0.9) fade = (1.0 - y) / 0.1;

      final opacity = p.opacity * fade;

      paint.color = const Color(0xFF003F91).withValues(alpha: opacity);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
