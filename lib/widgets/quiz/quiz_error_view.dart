import 'package:flutter/material.dart';

/// Displays an error state for the quiz screen with a back button.
class QuizErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onGoBack;

  const QuizErrorView({
    super.key,
    required this.errorMessage,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $errorMessage',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onGoBack, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
