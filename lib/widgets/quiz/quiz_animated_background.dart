import 'dart:math';
import 'package:flutter/material.dart';

/// A subtle animated gradient background that shifts colors slowly,
/// giving a dynamic "game-like" feel.
class QuizAnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const QuizAnimatedBackground({
    super.key,
    required this.child,
    this.isActive = true,
  });

  @override
  State<QuizAnimatedBackground> createState() => _QuizAnimatedBackgroundState();
}

class _QuizAnimatedBackgroundState extends State<QuizAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
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
        final double t = _controller.value;
        // Map t to an angle that oscillates smoothly
        final double angle = t * 2 * pi;
        final double dx = 0.3 + 0.2 * sin(angle);
        final double dy = 0.2 + 0.2 * cos(angle * 0.7);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(dx - 0.3, dy - 0.3),
              end: Alignment(dx + 0.3, dy + 0.3),
              colors: widget.isActive
                  ? const [
                      Color(0xFF1E293B), // slate-800
                      Color(0xFF312E81), // indigo-900
                      Color(0xFF1E2258),
                    ]
                  : const [Color(0xFFF4F6FB), Color(0xFFF4F6FB)],
            ),
          ),
          child: child,
        );
      },
    );
  }
}
