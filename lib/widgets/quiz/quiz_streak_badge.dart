import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// An animated streak multiplier badge with a fire Lottie animation.
class QuizStreakBadge extends StatelessWidget {
  final AnimationController animationController;
  final int consecutiveCorrect;

  const QuizStreakBadge({
    super.key,
    required this.animationController,
    required this.consecutiveCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final double bonusMultiplier = (consecutiveCorrect - 1) * 0.5;
    final double totalMultiplier = 1.0 + bonusMultiplier;
    final String multiplierText = totalMultiplier.toStringAsFixed(1);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final double pulse = animationController.value;
        final double scale = 0.92 + (pulse * 0.12);
        final double glowRadius = 10.0 + (pulse * 8.0);
        final double glowAlpha = 0.28 + (pulse * 0.22);

        return Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4500).withValues(alpha: glowAlpha),
                blurRadius: glowRadius,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: scale * 1.02,
                child: Lottie.asset(
                  'lib/assets/lottie/fire.lottie',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
              SizedBox(
                width: 58,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    multiplierText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
