// fasan_ui – short own tones for taps. MPL-2.0
//
// Nutzer 02.11.: Der Systemklick (SystemSound.click) blieb auf dem S23 stumm, obwohl Ton an war. Darum eigene, leise Töne:
// erzeugt zur Laufzeit (reine Sinus-Töne mit Hüllkurve, kein fremdes Material, keine Lizenzfrage), abgespielt mit audioplayers
// (MIT; pub.dev/packages/audioplayers) als Bytes. Android-Nutzungsart „assistanceSonification“ = Oberflächentöne (AudioAttributes
// USAGE_ASSISTANCE_SONIFICATION, developer.android.com): der Ton läuft auf dem Systemkanal, folgt Lautstärke und Lautlos-Modus
// des Handys (nicht auf One UI geprüft) und nimmt keinen Audio-Fokus, die Musik des Nutzers läuft weiter.
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

  static final List<AudioPlayer> _pool = [];
  static int _next = 0;
  static bool _broken = false;

  /// Tests: skip the audio plugin and use the system click.
  @visibleForTesting
  static bool disabled = false;

  /// Quiet by design: UI tones are part of the touch, not the music.
  static const double volume = 0.35;

  static final _context = AudioContext(
    android: const AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  static Future<void> play(FasanFeel feel) async {
    if (_broken || disabled) return _fallback();
    try {
      if (_pool.isEmpty) {
        for (var i = 0; i < 3; i++) {
          final p = AudioPlayer();
          await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          await p.setAudioContext(_context);
          _pool.add(p);
        }
      }
      final p = _pool[_next++ % _pool.length];
      // never wait longer than a moment for the platform: a tone that arrives late is worse than none
      await p.play(BytesSource(_tones[feel]!, mimeType: 'audio/wav'), volume: volume).timeout(const Duration(seconds: 2));
    } catch (_) {
      _broken = true; // no plugin: use the system click from now on
      await _fallback();
    }
  }

  static Future<void> _fallback() => SystemSound.play(SystemSoundType.click);
}
