import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// An animated streak multiplier badge with a fire Lottie animation
/// and combo counter text.
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
    // Additive streak bonus: each consecutive correct beyond 1st adds 1 bonus point.
    final int streakBonus = consecutiveCorrect - 1;
    final String multiplierText = '+$streakBonus';

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final double pulse = animationController.value;
        final double scale = 0.92 + (pulse * 0.12);
        final double glowRadius = 2.0 + (pulse * 2.0);
        final double glowAlpha = 0.04 + (pulse * 0.04);

        return Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF808080).withValues(alpha: glowAlpha),
                blurRadius: glowRadius,
                offset: const Offset(0, 1),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 58,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        multiplierText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'COMBO',
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.8 + (pulse * 0.2),
                      ),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
