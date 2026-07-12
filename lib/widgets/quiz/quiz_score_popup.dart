import 'package:flutter/material.dart';

/// A floating "+X pts" popup that animates upward and fades out.
/// Supports negative values for penalty deductions (shown in red with minus).
class QuizScorePopup extends StatefulWidget {
  final int points;
  final bool isTimed;

  const QuizScorePopup({super.key, required this.points, this.isTimed = false});

  @override
  State<QuizScorePopup> createState() => _QuizScorePopupState();
}

class _QuizScorePopupState extends State<QuizScorePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _yAnimation = Tween<double>(
      begin: 0,
      end: -80,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 0.4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 0.6),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.3,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 0.3,
      ),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 0.7),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isPenalty => widget.points < 0;

  Color get _popupColor {
    if (_isPenalty) return const Color(0xFFEF4444); // Red for deductions
    if (widget.isTimed) return const Color(0xFFF59E0B); // Amber for timed
    return const Color(0xFF4ADE80); // Green for normal correct
  }

  IconData get _popupIcon {
    if (_isPenalty) return Icons.remove_rounded;
    if (widget.isTimed) return Icons.bolt_rounded;
    return Icons.add_rounded;
  }

  String get _popupText {
    if (_isPenalty) return '${widget.points} pts';
    return '+${widget.points} pts';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _yAnimation.value),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _popupColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _popupColor.withValues(alpha: 0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_popupIcon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              _popupText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
