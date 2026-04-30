import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences.dart';

enum SoundEffect {
  move('sounds/move.mp3'),
  capture('sounds/capture.mp3'),
  check('sounds/check.mp3'),
  correct('sounds/correct.mp3', volume: 0.35),
  wrong('sounds/wrong.mp3', volume: 0.35),
  hint('sounds/hint.mp3'),
  roundComplete('sounds/round_complete.mp3');

  const SoundEffect(this.assetPath, {this.volume = 1.0});
  final String assetPath;
  final double volume;
}

class SoundService {
  SoundService();

  bool muted = false;
  final Map<SoundEffect, AudioPlayer> _players = {};
  final Set<SoundEffect> _missing = {};
  bool _warmed = false;

  /// Preloads every sound asset so the first call to [play] doesn't pay
  /// the cost of decoding + setting up the audio source. Without this
  /// the first user move feels laggy because audio playback waits on
  /// asset resolution.
  Future<void> warmup() async {
    if (_warmed) return;
    _warmed = true;
    for (final effect in SoundEffect.values) {
      try {
        final player = AudioPlayer();
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setSource(AssetSource(effect.assetPath));
        if (effect.volume != 1.0) {
          await player.setVolume(effect.volume);
        }
        _players[effect] = player;
      } catch (e) {
        _missing.add(effect);
        if (kDebugMode) {
          debugPrint(
            'SoundService warmup: ${effect.assetPath}: $e',
          );
        }
      }
    }
  }

  Future<void> play(SoundEffect effect) async {
    if (muted) return;
    if (_missing.contains(effect)) return;
    final warmPlayer = _players[effect];
    if (warmPlayer != null) {
      try {
        await warmPlayer.seek(Duration.zero);
        await warmPlayer.resume();
        return;
      } catch (e) {
        _missing.add(effect);
        if (kDebugMode) {
          debugPrint(
            'SoundService warm play: ${effect.assetPath}: $e',
          );
        }
        return;
      }
    }
    // Cold path: warmup didn't run (or failed). Fall back to direct play.
    try {
      final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _players[effect] = player;
      if (effect.volume != 1.0) {
        await player.setVolume(effect.volume);
      }
      await player.play(AssetSource(effect.assetPath));
    } catch (e) {
      _missing.add(effect);
    }
  }

  /// Schedules [effect] to play after [delay]. If [delay] is zero or
  /// negative, plays immediately on the same microtask.
  void playAfter(SoundEffect effect, Duration delay) {
    if (muted) return;
    if (delay <= Duration.zero) {
      play(effect);
      return;
    }
    Future.delayed(delay, () => play(effect));
  }

  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  // Mirror the muted preference into the service whenever it changes.
  ref.listen<bool>(
    mutedProvider,
    (prev, next) => service.muted = next,
    fireImmediately: true,
  );
  ref.onDispose(service.dispose);
  return service;
});
