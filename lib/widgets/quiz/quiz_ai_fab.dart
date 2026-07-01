import 'package:flutter/material.dart';

/// Animated floating action button that invites the user to chat with AI.
class QuizAiFab extends StatelessWidget {
  final AnimationController animationController;
  final VoidCallback onPressed;

  const QuizAiFab({
    super.key,
    required this.animationController,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final double scale = 1.0 + (animationController.value * 0.1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Floating bubble hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Need assistance?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Pulsing Floating Action Button
            Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF141053).withValues(alpha: 0.4),
                      blurRadius: 10 * animationController.value,
                      spreadRadius: 3 * animationController.value,
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: onPressed,
                  backgroundColor: const Color(0xFF141053),
                  mini: false,
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
