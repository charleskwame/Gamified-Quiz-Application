import 'package:flutter_test/flutter_test.dart';
import 'package:gamified_quiz_app/app.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify the app renders without errors
    expect(tester.takeException(), isNull);
  });
}
