import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

class AudioService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBgm() async {
    try {
      await _bgmPlayer.play(AssetSource('audio/Compass_and_Pine.mp3'), volume: 0.3);
    } catch (e) {
      // Ignorer l'erreur d'audio (par ex. sur simulateur ou test)
    }
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  Future<void> playIslandFound() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/island_found.wav'));
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  Future<void> playTreasureGreat() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/treasure_great.wav'));
    } catch (e) {
      // Ignorer l'erreur
    }
  }

  Future<void> playPoorLoot() async {
    try {
      await _sfxPlayer.play(AssetSource('audio/poor_loot.wav'));
    } catch (e) {
      // Ignorer l'erreur
    }
  }
}
