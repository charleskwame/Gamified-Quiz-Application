import 'package:flutter/material.dart';

/// Displays a game-like loading state for the quiz screen.
class QuizLoadingView extends StatefulWidget {
  const QuizLoadingView({super.key});

  @override
  State<QuizLoadingView> createState() => _QuizLoadingViewState();
}

class _QuizLoadingViewState extends State<QuizLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF111C4A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated game icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 0.85 + (_pulseController.value * 0.15);
                  final opacity = 0.6 + (_pulseController.value * 0.4);
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 52,
                          color: Color(0xFF818CF8),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Assembling your challenge...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Animated loading text
              AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  final dotCount = (_dotsController.value * 3).floor() + 1;
                  final dots = '.' * dotCount;
                  return Text(
                    'Fetching premium questions$dots',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              // Custom loading bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _pulseController.value,
                        minHeight: 4,
                        backgroundColor: const Color(0xFF2D3361),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fun loading tips that rotate
              const Text(
                '💡 Did you know? Answering faster earns bonus points!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5565),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
