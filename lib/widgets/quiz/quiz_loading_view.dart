import 'package:flutter/material.dart';

/// Displays a centered loading state for the quiz screen.
class QuizLoadingView extends StatelessWidget {
  const QuizLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF141053)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Assembling your challenge...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF121826),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fetching premium questions from the bank',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
