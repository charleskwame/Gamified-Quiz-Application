import 'package:flutter/material.dart';

/// A tappable floating pause indicator that appears in the bottom-left
/// corner of the quiz screen during timed/challenge mode. The user taps
/// it to freeze the countdown timer, giving them unlimited time to
/// answer the current question.
class QuizPauseIndicator extends StatefulWidget {
  final int pauseCount;
  final bool isPaused;
  final VoidCallback onTap;
  final AnimationController animationController;

  const QuizPauseIndicator({
    super.key,
    required this.pauseCount,
    required this.isPaused,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<QuizPauseIndicator> createState() => _QuizPauseIndicatorState();
}

class _QuizPauseIndicatorState extends State<QuizPauseIndicator> {
  @override
  Widget build(BuildContext context) {
    final bool hasPauses = widget.pauseCount > 0;
    final bool active = widget.isPaused && hasPauses;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final double pulse = widget.animationController.value;
        final double scale = active ? 0.95 + (pulse * 0.10) : 0.92;
        final double glowBlur = active ? 3.0 + (pulse * 3.0) : 1.0;
        final double glowAlpha = active ? 0.10 + (pulse * 0.10) : 0.03;

        return GestureDetector(
          onTap: (hasPauses && !active) ? widget.onTap : null,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: active
                      ? const Color(0xFFF59E0B).withValues(alpha: glowAlpha)
                      : hasPauses
                      ? const Color(0xFF003F91).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.02),
                  blurRadius: glowBlur,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pause icon
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                          : hasPauses
                          ? const Color(0xFFECF8F8)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: active
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.8)
                            : hasPauses
                            ? const Color(0xFF003F91).withValues(alpha: 0.6)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: active ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      active
                          ? Icons.pause_circle_filled_rounded
                          : hasPauses
                          ? Icons.pause_circle_rounded
                          : Icons.pause_circle_outline,
                      color: active
                          ? const Color(0xFFF59E0B)
                          : hasPauses
                          ? const Color(0xFF003F91)
                          : Colors.grey.withValues(alpha: 0.4),
                      size: 32,
                    ),
                  ),
                ),

                // Pause count badge
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
                          ? const Color(0xFFF59E0B)
                          : hasPauses
                          ? const Color(0xFF003F91)
                          : Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.pauseCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // "PAUSED" label when timer is frozen
                if (active)
                  Positioned(
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⏸',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
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
