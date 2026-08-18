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
    // Any transition away from the foreground stops the music; returning to
    // the foreground restarts it. This guarantees no audio continues once the
    // app is left (e.g. Home, app switcher, swipe-away, or closing).
    WidgetsBinding.instance.addObserver(this);
  }

  /// Singleton instance shared across the app.
  static final MusicService instance = MusicService._();

  static const String _musicAsset =
      'lib/assets/sound_effects/background-music.mp3';

  final AudioPlayer _player = AudioPlayer();

  bool _started = false;

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
      debugPrint('MusicService: background music started');
    } catch (e) {
      debugPrint('MusicService: failed to start background music: $e');
    }
  }

  /// Stops the background music.
  Future<void> stop() async {
    try {
      _started = false;
      await _player.stop();
      debugPrint('MusicService: background music stopped');
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
    debugPrint('MusicService: app lifecycle -> $state');
    switch (state) {
      case AppLifecycleState.resumed:
        // Idempotent: only restarts if the music had been stopped.
        _handleResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Any transition away from the foreground halts the audio.
        _handleStop();
        break;
    }
  }

  /// Forcefully stops playback when the app leaves the foreground.
  Future<void> _handleStop() async {
    if (!_started) return;
    await stop();
  }

  /// Restarts the loop when the app returns to the foreground.
  Future<void> _handleResume() async {
    await start();
  }
}
