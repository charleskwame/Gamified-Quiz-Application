import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'settings_service.dart';

/// Plays the app's background music as a continuous, looping track.
///
/// The music is fully independent from the sound effects ([SoundService]):
/// - It has its own enabled toggle and volume (0.0–1.0), stored separately in
///   [SettingsService].
/// - It loops continuously once started. The only controls are turning it on
///   or off (start/stop) and adjusting the volume (which applies live to the
///   running loop) — there is no ducking or pausing for other events.
class MusicService with WidgetsBindingObserver {
  MusicService._() {
    // Assets live under `lib/assets/`, so the AudioCache prefix must be empty.
    // (The default `assets/` prefix would resolve to a non-existent key.)
    _player.audioCache = AudioCache(prefix: '');
    _player.setReleaseMode(ReleaseMode.loop);
    // Pause the loop when the app leaves the foreground; resume on return.
    WidgetsBinding.instance.addObserver(this);
  }

  /// Singleton instance shared across the app.
  static final MusicService instance = MusicService._();

  static const String _musicAsset =
      'lib/assets/sound_effects/background-music.mp3';

  final AudioPlayer _player = AudioPlayer();

  bool _started = false;
  bool _pausedForBackground = false;

  /// Starts the background music loop if the user has it enabled.
  ///
  /// Safe to call multiple times — the loop won't restart if it's already
  /// playing.
  Future<void> start() async {
    try {
      if (_started) return;
      if (!await SettingsService.isMusicEnabled()) return;
      _started = true;
      await _player.setVolume(await SettingsService.getMusicVolume());
      await _player.play(AssetSource(_musicAsset));
    } catch (e) {
      debugPrint('MusicService: failed to start background music: $e');
    }
  }

  /// Stops the background music.
  Future<void> stop() async {
    try {
      _started = false;
      _pausedForBackground = false;
      await _player.stop();
    } catch (e) {
      debugPrint('MusicService: failed to stop background music: $e');
    }
  }

  /// Turns background music on or off (applies live).
  Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  /// Adjusts the background music volume live (0.0–1.0).
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      debugPrint('MusicService: failed to set volume: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleResume();
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _handleBackground();
        break;
      case AppLifecycleState.detached:
        _handleDetached();
        break;
      case AppLifecycleState.inactive:
        // Transient (dialogs, control center, incoming call) — leave as-is.
        break;
    }
  }

  /// Pauses the loop when the app is no longer visible.
  Future<void> _handleBackground() async {
    if (!_started) return;
    try {
      _pausedForBackground = true;
      await _player.pause();
    } catch (e) {
      debugPrint('MusicService: failed to pause background music: $e');
    }
  }

  /// Stops playback entirely when the app is being destroyed.
  Future<void> _handleDetached() async {
    try {
      _pausedForBackground = false;
      _started = false;
      await _player.stop();
    } catch (e) {
      debugPrint('MusicService: failed to stop background music: $e');
    }
  }

  /// Resumes the loop (or starts it) when the app returns to the foreground.
  Future<void> _handleResume() async {
    if (_pausedForBackground) {
      _pausedForBackground = false;
      try {
        await _player.resume();
      } catch (e) {
        debugPrint('MusicService: failed to resume background music: $e');
      }
    } else {
      // Not paused (e.g. cold start) — start if enabled.
      await start();
    }
  }
}
