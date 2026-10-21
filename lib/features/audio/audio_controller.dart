import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/quran_repository.dart';
import '../settings/settings_controller.dart';

/// Plays the bundled recitation (one mp3 per ayah, loaded from assets).
/// One shared instance is used by the reader and the mini-player.
///
/// Repeat count and speed are saved in Settings so they are remembered.
/// Only ayah-level highlighting is possible: there is no word timing data.
class AudioController extends ChangeNotifier {
  final SettingsController settings;
  final QuranRepository repo;
  final AudioPlayer _player = AudioPlayer();

  int? currentAyah;          // null = nothing loaded, mini-player hidden
  bool playing = false;
  bool hasError = false;
  bool _continuous = false;  // true after "Play all"
  int _repeatsDone = 0;      // how many times the current ayah has finished
  bool _handling = false;    // stops the "finished" event running twice

  AudioController(this.settings, this.repo) {
    _player.playerStateStream.listen(_onState);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  void _onState(PlayerState st) {
    final isPlaying =
        st.playing && st.processingState != ProcessingState.completed;
    if (isPlaying != playing) {
      playing = isPlaying;
      notifyListeners();
    }
    if (st.processingState == ProcessingState.completed) _onFinished();
  }

  /// Called when an ayah reaches its end: repeat it, go to the next, or stop.
  Future<void> _onFinished() async {
    if (_handling || currentAyah == null) return;
    _handling = true;
    try {
      _repeatsDone++;
      final times = settings.repeatCount; // 0 means loop forever
      final canGoNext = currentAyah! < repo.ayahs.length;
      if (times == 0 || _repeatsDone < times) {
        await _player.seek(Duration.zero);
        unawaited(_player.play());
      } else if ((_continuous || settings.autoNext) && canGoNext) {
        await playAyah(currentAyah! + 1, continuous: _continuous);
      } else {
        await _player.pause();
        await _player.seek(Duration.zero);
        playing = false;
        notifyListeners();
      }
    } finally {
      _handling = false;
    }
  }

  /// Start playing one ayah. [continuous] = keep going to the next ones.
  Future<void> playAyah(int n, {bool continuous = false}) async {
    if (n < 1 || n > repo.ayahs.length) return;
    currentAyah = n;
    _continuous = continuous;
    _repeatsDone = 0;
    hasError = false;
    notifyListeners();
    try {
      await _player.setAsset(repo.ayah(n).audioAsset);
      await _player.setSpeed(settings.audioSpeed);
      unawaited(_player.play());
    } catch (_) {
      // Missing file or browser problem: show a message, never crash.
      hasError = true;
      playing = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    final n = currentAyah;
    if (n == null) return;
    if (hasError) return playAyah(n, continuous: _continuous);
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      unawaited(_player.play());
    }
  }

  Future<void> next() async {
    if (currentAyah != null) await playAyah(currentAyah! + 1, continuous: _continuous);
  }

  Future<void> previous() async {
    if (currentAyah != null) await playAyah(currentAyah! - 1, continuous: _continuous);
  }

  Future<void> stop() async {
    await _player.stop();
    currentAyah = null;
    playing = false;
    _continuous = false;
    notifyListeners();
  }

  Future<void> setSpeed(double v) async {
    settings.update(() => settings.audioSpeed = v);
    await _player.setSpeed(v);
    notifyListeners();
  }

  void setRepeat(int times) {
    settings.update(() => settings.repeatCount = times);
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
