import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores lightweight user preferences using SharedPreferences.
///
/// Mirrors the existing `OnboardingService` pattern (a simple persisted bool).
class SettingsService {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _musicEnabledKey = 'music_enabled';
  static const String _musicVolumeKey = 'music_volume';
  static const String _particlesEnabledKey = 'particles_enabled';

  /// ValueNotifier that emits real-time changes to the particles enabled state.
  static final ValueNotifier<bool> particlesEnabledNotifier =
      ValueNotifier<bool>(true);

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

  /// Whether background music is enabled (defaults to true).
  static Future<bool> isMusicEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_musicEnabledKey) ?? true;
  }

  /// Persists the background music enabled state.
  static Future<void> setMusicEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);
  }

  /// Background music volume in 0.0–1.0 (defaults to 0.5).
  static Future<double> getMusicVolume() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_musicVolumeKey) ?? 0.5;
  }

  /// Persists the background music volume.
  static Future<void> setMusicVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, volume.clamp(0.0, 1.0));
  }

  // ── Particle Effects ──────────────────────────────────────────────────

  /// Whether ambient background particle effects are enabled (defaults to true).
  static Future<bool> isParticlesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_particlesEnabledKey) ?? true;
    if (particlesEnabledNotifier.value != enabled) {
      particlesEnabledNotifier.value = enabled;
    }
    return enabled;
  }

  /// Persists the background particle effects setting and notifies listeners.
  static Future<void> setParticlesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_particlesEnabledKey, enabled);
    particlesEnabledNotifier.value = enabled;
  }

  // ── Auto-Skip on Correct Answer ─────────────────────────────────────────

  static const String _autoSkipCorrectKey = 'auto_skip_correct';

  /// Whether to automatically advance to the next question after a short delay
  /// when the player answers correctly (defaults to false).
  static Future<bool> isAutoSkipCorrectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSkipCorrectKey) ?? false;
  }

  /// Persists the auto-skip-on-correct setting.
  static Future<void> setAutoSkipCorrectEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSkipCorrectKey, enabled);
  }
}

