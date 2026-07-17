import 'dart:math';
import 'package:flutter/material.dart';

/// A circular countdown timer with color transitions and pulse animation
/// when time is running low.
class QuizCircularTimer extends StatelessWidget {
  final AnimationController animationController;
  final int timeLeft;
  final int totalSeconds;

  const QuizCircularTimer({
    super.key,
    required this.animationController,
    required this.timeLeft,
    this.totalSeconds = 15,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = animationController.value;
    final bool isLow = timeLeft <= 4;
    final bool isCritical = timeLeft <= 2;

    Color timerColor;
    if (isCritical) {
      timerColor = const Color(0xFFEF4444);
    } else if (isLow) {
      timerColor = const Color(0xFFF59E0B);
    } else {
      timerColor = const Color(0xFF6366F1);
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        // Pulse effect when low
        final double pulse = isLow
            ? (0.94 + (0.06 * sin(animationController.value * 2 * pi)))
            : 1.0;

        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                CustomPaint(
                  size: const Size(48, 48),
                  painter: _CirclePainter(
                    progress: 1.0,
                    color: const Color(0xFFE8E9EB),
                    strokeWidth: 4,
                  ),
                ),
                // Progress arc
                CustomPaint(
                  size: const Size(48, 48),
                  painter: _CirclePainter(
                    progress: progress,
                    color: timerColor,
                    strokeWidth: 4,
                  ),
                ),
                // Time text
                Text(
                  '$timeLeft',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isCritical
                        ? const Color(0xFFEF4444)
                        : isLow
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF003F91),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // Start from top
      -2 * pi * progress, // Clockwise
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
