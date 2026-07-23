import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_quiz_app/screens/onboarding_tour_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('OnboardingTourScreen renders correctly and navigates', (
    WidgetTester tester,
  ) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingTourScreen(
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );

    // Initial page check
    expect(find.text('Welcome to Gamified Quiz!'), findsOneWidget);
    expect(completed, isFalse);

    // Click Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // Verify second page is shown
    expect(find.text('Your Command Center'), findsOneWidget);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify onComplete callback was executed
    expect(completed, isTrue);
  });
}
