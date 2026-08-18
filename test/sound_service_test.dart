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
  });
}
