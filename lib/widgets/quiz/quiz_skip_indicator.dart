import 'package:flutter/material.dart';

/// A tappable floating skip indicator that appears in the bottom-left
/// corner of the quiz screen. The user taps it to instantly skip the
/// current question without penalty and without breaking their streak.
class QuizSkipIndicator extends StatefulWidget {
  final int skipCount;
  final VoidCallback onTap;
  final AnimationController animationController;

  const QuizSkipIndicator({
    super.key,
    required this.skipCount,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<QuizSkipIndicator> createState() => _QuizSkipIndicatorState();
}

class _QuizSkipIndicatorState extends State<QuizSkipIndicator> {
  @override
  Widget build(BuildContext context) {
    final bool hasSkips = widget.skipCount > 0;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final double pulse = widget.animationController.value;
        final double scale = hasSkips ? 0.95 + (pulse * 0.08) : 0.92;

        return GestureDetector(
          onTap: hasSkips ? widget.onTap : null,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: hasSkips
                      ? const Color(
                          0xFF4ADE80,
                        ).withValues(alpha: 0.06 + (pulse * 0.06))
                      : Colors.grey.withValues(alpha: 0.02),
                  blurRadius: hasSkips ? 3.0 + (pulse * 2.0) : 1.0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Skip icon
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasSkips
                          ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: hasSkips
                            ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      hasSkips
                          ? Icons.skip_next_rounded
                          : Icons.skip_next_outlined,
                      color: hasSkips
                          ? const Color(0xFF4ADE80)
                          : Colors.grey.withValues(alpha: 0.4),
                      size: 32,
                    ),
                  ),
                ),

                // Skip count badge
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: hasSkips
                          ? const Color(0xFF4ADE80)
                          : Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.skipCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
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
