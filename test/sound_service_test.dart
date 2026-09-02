import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_quiz_app/services/settings_service.dart';
import 'package:gamified_quiz_app/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sound assets', () {
    // These exact keys must exist in the asset bundle, otherwise
    // SoundService (audioplayers AudioCache with an empty prefix) will fail
    // to resolve and play the sound effects.
    const assets = [
      'lib/assets/sound_effects/correct.mp3',
      'lib/assets/sound_effects/wrong.mp3',
      'lib/assets/sound_effects/level-up.mp3',
      'lib/assets/sound_effects/nav-click.mp3',
      'lib/assets/sound_effects/next.mp3',
      'lib/assets/sound_effects/purchasing.mp3',
      'lib/assets/sound_effects/session-complete.mp3',
      'lib/assets/sound_effects/background-music.mp3',
    ];

    for (final asset in assets) {
      test('$asset is bundled at the exact key', () async {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(0));
      });
    }
  });

  group('SoundService', () {
    test('exposes the navigation click sound effect', () async {
      expect(SoundService.instance.playNavClick, isA<Function>());
    });

    test('exposes the purchase sound effect', () async {
      expect(SoundService.instance.playPurchase, isA<Function>());
    });
  });

  group('SettingsService', () {
    test('sound is enabled by default', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SettingsService.isSoundEnabled(), isTrue);
    });

    test('persists the sound enabled state', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setSoundEnabled(false);
      expect(await SettingsService.isSoundEnabled(), isFalse);
    });

    test('music is enabled by default', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SettingsService.isMusicEnabled(), isTrue);
    });

    test('persists the music enabled state', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setMusicEnabled(false);
      expect(await SettingsService.isMusicEnabled(), isFalse);
    });

    test('music volume defaults to 0.5', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SettingsService.getMusicVolume(), 0.5);
    });

    test('particles are enabled by default', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await SettingsService.isParticlesEnabled(), isTrue);
      expect(SettingsService.particlesEnabledNotifier.value, isTrue);
    });

    test('persists the particles enabled state and updates notifier', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setParticlesEnabled(false);
      expect(await SettingsService.isParticlesEnabled(), isFalse);
      expect(SettingsService.particlesEnabledNotifier.value, isFalse);

      await SettingsService.setParticlesEnabled(true);
      expect(await SettingsService.isParticlesEnabled(), isTrue);
      expect(SettingsService.particlesEnabledNotifier.value, isTrue);
    });
  });
}
