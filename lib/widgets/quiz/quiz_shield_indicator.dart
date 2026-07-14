import 'package:flutter/material.dart';

/// A tappable floating shield indicator that appears in the bottom-left
/// corner of the quiz screen. The user taps it to activate a shield for
/// the current question. If they answer incorrectly, the shield absorbs
/// the penalty instead of deducting score.
class QuizShieldIndicator extends StatefulWidget {
  final int shieldsRemaining;
  final bool isShieldActive;
  final VoidCallback onTap;
  final AnimationController animationController;

  const QuizShieldIndicator({
    super.key,
    required this.shieldsRemaining,
    required this.isShieldActive,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<QuizShieldIndicator> createState() => _QuizShieldIndicatorState();
}

class _QuizShieldIndicatorState extends State<QuizShieldIndicator> {
  @override
  Widget build(BuildContext context) {
    final bool hasShields = widget.shieldsRemaining > 0;
    final bool active = widget.isShieldActive && hasShields;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final double pulse = widget.animationController.value;
        final double scale = active ? 0.95 + (pulse * 0.10) : 0.92;
        final double glowRadius = active ? 3.0 + (pulse * 3.0) : 1.0;
        final double glowAlpha = active ? 0.10 + (pulse * 0.10) : 0.03;

        return GestureDetector(
          onTap: hasShields ? widget.onTap : null,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: active
                      ? const Color(0xFFFFD700).withValues(alpha: glowAlpha)
                      : const Color(0xFF6366F1).withValues(alpha: glowAlpha),
                  blurRadius: glowRadius,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Shield icon
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : hasShields
                          ? const Color(0xFF6366F1).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFFFD700).withValues(alpha: 0.8)
                            : hasShields
                            ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: active ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      active ? Icons.shield_rounded : Icons.shield_outlined,
                      color: active
                          ? const Color(0xFFFFD700)
                          : hasShields
                          ? const Color(0xFF818CF8)
                          : Colors.grey.withValues(alpha: 0.4),
                      size: 28,
                    ),
                  ),
                ),

                // Shield count badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFFD700)
                          : hasShields
                          ? const Color(0xFF6366F1)
                          : Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.shieldsRemaining}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: active ? const Color(0xFF1E1B4B) : Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // "ACTIVE" label when shield is toggled on
                if (active)
                  Positioned(
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ON',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                          letterSpacing: 1,
                          height: 1.2,
                        ),
                      ),
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
