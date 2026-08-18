import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamified_quiz_app/services/settings_service.dart';

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
      'lib/assets/sound_effects/next.mp3',
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

    test('persists the music volume (clamped to 0..1)', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.setMusicVolume(0.8);
      expect(await SettingsService.getMusicVolume(), 0.8);
      await SettingsService.setMusicVolume(1.5);
      expect(await SettingsService.getMusicVolume(), 1.0);
      await SettingsService.setMusicVolume(-0.2);
      expect(await SettingsService.getMusicVolume(), 0.0);
    });
  });
}
