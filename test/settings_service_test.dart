import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_quiz_app/services/settings_service.dart';
import 'package:gamified_quiz_app/widgets/home/particle_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService Particle Settings', () {
    test('particles are enabled by default', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SettingsService.isParticlesEnabled(), isTrue);
      expect(SettingsService.particlesEnabledNotifier.value, isTrue);
    });

    test('persists particles disabled and updates notifier', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setParticlesEnabled(false);
      expect(await SettingsService.isParticlesEnabled(), isFalse);
      expect(SettingsService.particlesEnabledNotifier.value, isFalse);
    });

    test('persists particles enabled and updates notifier', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setParticlesEnabled(true);
      expect(await SettingsService.isParticlesEnabled(), isTrue);
      expect(SettingsService.particlesEnabledNotifier.value, isTrue);
    });
  });

  group('ParticleBackground Widget', () {
    testWidgets('renders child content and reflects particle setting',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setParticlesEnabled(true);

      await tester.pumpWidget(
        const MaterialApp(
          home: ParticleBackground(
            child: Text('Quiz Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Quiz Content'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Disable particles and pump
      await SettingsService.setParticlesEnabled(false);
      await tester.pump();

      expect(find.text('Quiz Content'), findsOneWidget);
    });
  });
}

