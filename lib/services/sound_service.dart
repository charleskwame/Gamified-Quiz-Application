import 'package:audioplayers/audioplayers.dart';
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
    _preload();
  }

  /// Singleton instance shared across the app.
  static final SoundService instance = SoundService._();

  static const String _correctAsset = 'lib/assets/sound_effects/correct.mp3';
  static const String _wrongAsset = 'lib/assets/sound_effects/wrong.mp3';
  static const String _levelUpAsset = 'lib/assets/sound_effects/level-up.mp3';

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _levelUpPlayer = AudioPlayer();

  /// Caches the sound assets and tunes the players for low-latency playback.
  Future<void> _preload() async {
    try {
      _sfxPlayer.setReleaseMode(ReleaseMode.stop);
      _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
      _levelUpPlayer.setReleaseMode(ReleaseMode.stop);
      _levelUpPlayer.setPlayerMode(PlayerMode.lowLatency);
      await AudioCache.instance.loadAll([
        _correctAsset,
        _wrongAsset,
        _levelUpAsset,
      ]);
    } catch (_) {
      // Audio is best-effort: never let a missing asset crash the quiz.
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
    } catch (_) {
      // Best-effort playback.
    }
  }

  Future<void> _playSfx(String asset) async {
    if (!await SettingsService.isSoundEnabled()) return;
    try {
      // Interrupt any in-flight SFX so rapid taps restart cleanly.
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(asset));
    } catch (_) {
      // Best-effort playback.
    }
  }
}
