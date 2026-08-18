import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

/// Plays short sound effects for quiz feedback: correct, wrong, and level-up.
///
/// Design notes for the game's needs:
/// - [playCorrect] and [playWrong] share a single low-latency player with
///   `ReleaseMode.stop`. Each call stops any in-flight sound before playing, so
///   rapid consecutive answers restart cleanly instead of overlapping or
///   stuttering.
/// - [playLevelUp] uses its own dedicated player so the celebration fanfare is
///   never cut off by quiz feedback SFX.
/// - All assets are preloaded up front to keep first-play latency minimal.
/// - Every play call respects the user's Sound Effects setting in
///   [SettingsService].
class SoundService {
  SoundService._() {
    // Assets live under `lib/assets/`, so the AudioCache prefix must be empty.
    // (The default `assets/` prefix would resolve to a non-existent key.)
    _sfxPlayer.audioCache = _cache;
    _levelUpPlayer.audioCache = _cache;
    _preload();
  }

  /// Singleton instance shared across the app.
  static final SoundService instance = SoundService._();

  static const String _correctAsset = 'lib/assets/sound_effects/correct.mp3';
  static const String _wrongAsset = 'lib/assets/sound_effects/wrong.mp3';
  static const String _levelUpAsset = 'lib/assets/sound_effects/level-up.mp3';
  static const String _navClickAsset = 'lib/assets/sound_effects/nav-click.mp3';
  static const String _nextAsset = 'lib/assets/sound_effects/next.mp3';
  static const String _purchaseAsset =
      'lib/assets/sound_effects/purchasing.mp3';
  static const String _sessionCompleteAsset =
      'lib/assets/sound_effects/session-complete.mp3';

  // Assets live under `lib/assets/`, so the AudioCache prefix must be empty
  // (the default `assets/` prefix would resolve to a non-existent key).
  final AudioCache _cache = AudioCache(prefix: '');

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _levelUpPlayer = AudioPlayer();

  /// Caches the sound assets and tunes the players for low-latency playback.
  Future<void> _preload() async {
    try {
      _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      _levelUpPlayer.setReleaseMode(ReleaseMode.stop);
      _levelUpPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _cache.loadAll([
        _correctAsset,
        _wrongAsset,
        _levelUpAsset,
        _navClickAsset,
        _nextAsset,
        _sessionCompleteAsset,
        _purchaseAsset,
      ]);
    } catch (e) {
      // Audio is best-effort: never let a missing asset crash the quiz.
      debugPrint('SoundService: failed to preload sound assets: $e');
    }
  }

  /// Plays the "correct answer" sound.
  Future<void> playCorrect() => _playSfx(_correctAsset);

  /// Plays the "wrong answer" sound.
  Future<void> playWrong() => _playSfx(_wrongAsset);

  /// Plays the "level up" fanfare.
  Future<void> playLevelUp() async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      await _levelUpPlayer.stop();
      await _levelUpPlayer.play(AssetSource(_levelUpAsset));
    } catch (e) {
      debugPrint('SoundService: failed to play level-up sound: $e');
    }
  }

  /// Plays the navigation-item click sound.
  Future<void> playNavClick() => _playSfx(_navClickAsset);

  /// Plays the "next" tap sound (e.g. Enter Quest / Next Question).
  Future<void> playNext() => _playSfx(_nextAsset);

  /// Plays the shop purchase sound when an item is bought successfully.
  Future<void> playPurchase() => _playSfx(_purchaseAsset);

  /// Plays the "session complete" sound when a quiz session finishes.
  Future<void> playSessionComplete() => _playSfx(_sessionCompleteAsset);

  Future<void> _playSfx(String asset) async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      // Interrupt any in-flight SFX so rapid taps restart cleanly.
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(asset));
    } catch (e) {
      debugPrint('SoundService: failed to play sound: $e');
    }
  }
}
