import 'dart:math';
import 'package:flutter/material.dart';

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
    )..repeat();

    // Generate 25 particles with random initial positions
    for (int i = 0; i < 25; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: 1.5 + _random.nextDouble() * 2.5,
          opacity: 0.15 + _random.nextDouble() * 0.35,
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
      child: widget.child,
      builder: (context, child) {
        return SizedBox.expand(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7F7F7),
                  Color(0xFFFBFBFB),
                  Color(0xFFF5F5F5),
                  Color(0xFFF0F0F0),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Particle layer
                if (widget.isActive)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ParticlePainter(
                        particles: _particles,
                        progress: _controller,
                      ),
                    ),
                  ),
                // Content layer
                child!,
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

      paint.color = Colors.black.withValues(alpha: opacity * 0.5);
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
