import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/quiz_engine.dart';

/// A game-ified option tile with animations, letter badges, and
/// correct/incorrect feedback with shake and glow effects.
class QuizGameOption extends StatefulWidget {
  final String option;
  final String correctAnswer;
  final String? selectedOption;
  final bool isAnswered;
  final VoidCallback onTap;
  final int index;

  const QuizGameOption({
    super.key,
    required this.option,
    required this.correctAnswer,
    required this.selectedOption,
    required this.isAnswered,
    required this.onTap,
    required this.index,
  });

  @override
  State<QuizGameOption> createState() => _QuizGameOptionState();
}

class _QuizGameOptionState extends State<QuizGameOption>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _scaleController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..value = 1.0;

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _scaleController.forward(from: 0.0).then((_) {
      _scaleController.reverse(from: 1.0);
    });

    final isSelectedCorrect = QuizEngine.isOptionCorrect(
      widget.option,
      widget.correctAnswer,
    );
    if (!isSelectedCorrect) {
      _shakeController.forward(from: 0.0);
    }
    widget.onTap();
  }

  bool get _isSelected => widget.selectedOption == widget.option;
  bool get _isCorrectOption =>
      QuizEngine.isOptionCorrect(widget.option, widget.correctAnswer);

  static const List<String> _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF3D4375);
    Color bgColor = const Color(0xFF2A2F5A);
    Color labelBg = const Color(0xFF3D4375);
    Color labelTextColor = Colors.white70;
    IconData? stateIcon;
    Color iconColor = Colors.white;

    if (widget.isAnswered) {
      if (_isCorrectOption) {
        borderColor = const Color(0xFF4ADE80);
        bgColor = const Color(0xFF1A3A2A);
        labelBg = const Color(0xFF4ADE80);
        labelTextColor = Colors.white;
        stateIcon = Icons.check_circle_rounded;
        iconColor = const Color(0xFF4ADE80);
      } else if (_isSelected) {
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFF3A1A1A);
        labelBg = const Color(0xFFEF4444);
        labelTextColor = Colors.white;
        stateIcon = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _scaleController]),
      builder: (context, child) {
        // Scale down on tap
        final double scale = _scaleController.isAnimating
            ? 0.95 + (_scaleController.value * 0.05)
            : 1.0;

        // Shake offset
        double shakeX = 0;
        if (_shakeController.isAnimating) {
          shakeX = sin(_shakeAnimation.value * 4 * pi) * 6;
        }

        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            if (widget.isAnswered && _isCorrectOption)
              BoxShadow(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isAnswered ? null : _handleTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white10,
            highlightColor: Colors.white.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: labelBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _labels[widget.index % _labels.length],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: labelTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.option,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            _isSelected ||
                                (widget.isAnswered && _isCorrectOption)
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (stateIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(stateIcon, color: iconColor, size: 22),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
