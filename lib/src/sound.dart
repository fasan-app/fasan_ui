// fasan_ui – short own tones for taps. MPL-2.0
//
// Nutzer 02.11.: Der Systemklick (SystemSound.click) blieb auf dem S23 stumm, obwohl Ton an war. Darum eigene, leise Töne:
// erzeugt zur Laufzeit (reine Sinus-Töne mit Hüllkurve, kein fremdes Material, keine Lizenzfrage), abgespielt mit audioplayers
// (MIT; pub.dev/packages/audioplayers) als Bytes. Android-Nutzungsart „assistanceSonification“ = Oberflächentöne (AudioAttributes
// USAGE_ASSISTANCE_SONIFICATION, developer.android.com): der Ton läuft auf dem Systemkanal, folgt Lautstärke und Lautlos-Modus
// des Handys (nicht auf One UI geprüft) und nimmt keinen Audio-Fokus, die Musik des Nutzers läuft weiter.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import 'scope.dart';

/// A tone: sine parts (Hz, relative level) with a fast attack and an exponential decay.
Uint8List fasanTone({required List<(double, double)> partials, required double ms, double decayMs = 18, double level = 0.8, int rate = 22050}) {
  final n = (rate * ms / 1000).round();
  final pcm = ByteData(44 + n * 2);
  void ascii(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      pcm.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  pcm.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  pcm.setUint32(16, 16, Endian.little);
  pcm.setUint16(20, 1, Endian.little); // PCM
  pcm.setUint16(22, 1, Endian.little); // mono
  pcm.setUint32(24, rate, Endian.little);
  pcm.setUint32(28, rate * 2, Endian.little);
  pcm.setUint16(32, 2, Endian.little);
  pcm.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  pcm.setUint32(40, n * 2, Endian.little);
  final norm = partials.fold<double>(0, (a, p) => a + p.$2);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final attack = math.min(1.0, i / (rate * 0.0015)); // 1.5 ms: no click at the start
    final env = attack * math.exp(-t * 1000 / decayMs);
    var v = 0.0;
    for (final (f, a) in partials) {
      v += a * math.sin(2 * math.pi * f * t);
    }
    pcm.setInt16(44 + i * 2, (v / norm * env * level * 32767).round().clamp(-32767, 32767), Endian.little);
  }
  return pcm.buffer.asUint8List();
}

/// Plays the tap tones. Falls back to the system click when the audio plugin is not there (tests, other platforms).
abstract final class FasanSound {
  static final Map<FasanFeel, Uint8List> _tones = {
    FasanFeel.tap: fasanTone(partials: const [(1900, 1), (3800, 0.25)], ms: 38, decayMs: 9, level: 0.7),
    FasanFeel.confirm: fasanTone(partials: const [(880, 1), (1320, 0.6)], ms: 120, decayMs: 38, level: 0.7),
    FasanFeel.snap: fasanTone(partials: const [(1400, 1), (2100, 0.3)], ms: 60, decayMs: 15, level: 0.75),
    FasanFeel.warn: fasanTone(partials: const [(330, 1), (495, 0.5)], ms: 160, decayMs: 55, level: 0.75),
  };

  // One prepared player per tone: the bytes are set once, a tap only restarts it (no decoding on the tap).
  static final Map<FasanFeel, AudioPlayer> _players = {};

  /// What the log shows (Protokoll „darstellung.ton“): why there was no sound, how often it played.
  static String? lastError;
  static int plays = 0, failures = 0;
  static String mode = 'mediaPlayer';

  /// Tests: skip the audio plugin and use the system click.
  @visibleForTesting
  static bool disabled = false;

  /// Quiet by design: UI tones are part of the touch, not the music.
  static const double volume = 0.4;

  // 0.1.23 used PlayerMode.lowLatency (SoundPool) and BytesSource together. The plugin source says it cannot:
  // „Bytes sources are not supported on LOW_LATENCY mode yet.“ (audioplayers_android 5.3.0, BytesSource.kt). The error was
  // swallowed and the silent system click took over – that was the missing sound on the S23. Now: the normal MediaPlayer mode,
  // which supports bytes (Android ≥ 6). Usage „media“ follows the media volume, which people keep above zero; the earlier
  // „assistanceSonification“ follows the system-sound slider, which is often at zero (nicht auf One UI geprüft).
  static final _context = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  /// Plays a tone. Returns null when it went to the plugin, else the reason it did not (shown by the test button).
  static Future<String?> play(FasanFeel feel) async {
    if (disabled) {
      await _fallback();
      return 'aus (Test)';
    }
    try {
      var p = _players[feel];
      if (p == null) {
        p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.mediaPlayer);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setAudioContext(_context);
        await p.setVolume(volume);
        await p.setSource(BytesSource(_tones[feel]!, mimeType: 'audio/wav'));
        _players[feel] = p;
      }
      // a tone that arrives late is worse than none: do not wait longer than a moment for the platform
      await p.seek(Duration.zero).timeout(const Duration(seconds: 2));
      await p.resume().timeout(const Duration(seconds: 2));
      plays++;
      failures = 0;
      lastError = null;
      return null;
    } catch (e) {
      lastError = '$e';
      failures++;
      final p = _players.remove(feel);
      if (p != null) unawaited(p.dispose());
      // after three failures in a row the plugin is not there (tests, other platforms): system click
      if (failures >= 3) await _fallback();
      return lastError;
    }
  }

  static Future<void> _fallback() => SystemSound.play(SystemSoundType.click);
}
