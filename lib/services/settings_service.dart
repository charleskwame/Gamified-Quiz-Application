import 'package:shared_preferences/shared_preferences.dart';

/// Stores lightweight user preferences using SharedPreferences.
///
/// Mirrors the existing `OnboardingService` pattern (a simple persisted bool).
class SettingsService {
  static const String _soundEnabledKey = 'sound_enabled';

  /// Whether sound effects are enabled (defaults to true).
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// Persists the sound effects enabled state.
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }
}
