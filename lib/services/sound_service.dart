import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_preferences.dart';

enum SoundEffect {
  move('sounds/move.mp3'),
  capture('sounds/capture.mp3'),
  check('sounds/check.mp3'),
  correct('sounds/correct.mp3'),
  wrong('sounds/wrong.mp3'),
  hint('sounds/hint.mp3'),
  roundComplete('sounds/round_complete.mp3');

  const SoundEffect(this.assetPath);
  final String assetPath;
}

class SoundService {
  SoundService();

  bool muted = false;
  final Map<SoundEffect, AudioPlayer> _players = {};
  final Set<SoundEffect> _missing = {};

  Future<void> play(SoundEffect effect) async {
    if (muted) return;
    if (_missing.contains(effect)) return;
    var player = _players[effect];
    if (player == null) {
      player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _players[effect] = player;
    }
    try {
      await player.stop();
      await player.play(AssetSource(effect.assetPath));
    } catch (e) {
      _missing.add(effect);
      if (kDebugMode) {
        debugPrint('SoundService: missing or unplayable ${effect.assetPath}: $e');
      }
    }
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
