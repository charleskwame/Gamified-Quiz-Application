import 'package:flutter/material.dart';

/// A tappable floating "No Deductions" indicator that appears in the
/// bottom-left corner of the quiz screen. Tapping it consumes one
/// "No Deductions" power-up and activates it for the rest of the quiz —
/// all point deductions (wrong answers and timeouts) are negated while
/// it is active.
class QuizNoDeductionsIndicator extends StatefulWidget {
  final int noDeductionsCount;
  final bool isActive;
  final VoidCallback onTap;
  final AnimationController animationController;

  const QuizNoDeductionsIndicator({
    super.key,
    required this.noDeductionsCount,
    required this.isActive,
    required this.onTap,
    required this.animationController,
  });

  @override
  State<QuizNoDeductionsIndicator> createState() =>
      _QuizNoDeductionsIndicatorState();
}

class _QuizNoDeductionsIndicatorState extends State<QuizNoDeductionsIndicator> {
  static const Color _accent = Color(0xFF8B5CF6); // purple accent

  @override
  Widget build(BuildContext context) {
    final bool hasItems = widget.noDeductionsCount > 0;
    final bool active = widget.isActive && hasItems;

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        final double pulse = widget.animationController.value;
        final double scale = active ? 0.95 + (pulse * 0.10) : 0.92;
        final double glowRadius = active ? 3.0 + (pulse * 3.0) : 1.0;
        final double glowAlpha = active ? 0.10 + (pulse * 0.10) : 0.03;

        return GestureDetector(
          onTap: (hasItems && !active) ? widget.onTap : null,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: active
                      ? _accent.withValues(alpha: glowAlpha)
                      : hasItems
                      ? const Color(0xFF003F91).withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.02),
                  blurRadius: glowRadius,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // No-Deductions icon (blocked = no penalty)
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active
                          ? _accent.withValues(alpha: 0.2)
                          : hasItems
                          ? const Color(0xFFECF8F8)
                          : Colors.grey.withValues(alpha: 0.1),
                      border: Border.all(
                        color: active
                            ? _accent.withValues(alpha: 0.8)
                            : hasItems
                            ? const Color(0xFF003F91).withValues(alpha: 0.6)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: active ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      active ? Icons.block_rounded : Icons.block,
                      color: active
                          ? _accent
                          : hasItems
                          ? const Color(0xFF003F91)
                          : Colors.grey.withValues(alpha: 0.4),
                      size: 30,
                    ),
                  ),
                ),

                // Count badge
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
                          ? _accent
                          : hasItems
                          ? const Color(0xFF003F91)
                          : Colors.grey.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${widget.noDeductionsCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                // "ON" label when active
                if (active)
                  Positioned(
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ON',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
