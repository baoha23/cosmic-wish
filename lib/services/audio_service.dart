import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  AudioService();

  final AudioPlayer _ambient = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();
  bool _ambientReady = false;
  final Set<String> _sfxLoaded = <String>{};

  Future<void> init() async {
    if (_ambientReady) return;
    try {
      await _ambient.setAsset('assets/audio/ambient.wav');
      await _ambient.setLoopMode(LoopMode.all);
      _ambientReady = true;
    } catch (e) {
      debugPrint('Ambient init failed: $e');
    }
  }

  Future<void> playAmbient() async {
    try {
      await init();
      await _ambient.setVolume(0.35);
      if (!_ambient.playing) await _ambient.play();
    } catch (e) {
      debugPrint('playAmbient failed: $e');
    }
  }

  Future<void> stopAmbient() async {
    try {
      await _ambient.stop();
    } catch (_) {}
  }

  Future<void> playChime() => _playSfx('assets/audio/chime.wav');
  Future<void> playSwoosh() => _playSfx('assets/audio/swoosh.wav');
  Future<void> playTap() => _playSfx('assets/audio/tap.wav');

  Future<void> _playSfx(String path) async {
    try {
      // Cache: setAsset is expensive on just_audio — only do it once
      // per path per service lifetime.
      if (_sfxLoaded.add(path)) {
        await _sfx.setAsset(path);
      }
      await _sfx.seek(Duration.zero);
      await _sfx.play();
    } catch (e) {
      debugPrint('SFX failed ($path): $e');
    }
  }

  Future<void> dispose() async {
    await _ambient.dispose();
    await _sfx.dispose();
  }
}
