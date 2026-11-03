// fasan_ui – short own tones for taps. MPL-2.0
//
// Nutzer 02.11.: Der Systemklick (SystemSound.click) blieb auf dem S23 stumm, obwohl Ton an war. Darum eigene, leise Töne:
// erzeugt zur Laufzeit (reine Sinus-Töne mit Hüllkurve, kein fremdes Material, keine Lizenzfrage).
// 0.1.23: audioplayers lowLatency + Bytes ging nicht (Plugin-Quelltext). 0.1.24: audioplayers MediaPlayer: erster Ton dünn, spätere lauter,
// manche zu spät oder doppelt (Nutzer 03.11.). Jetzt: eigener nativer AudioTrack (MODE_STATIC, android/…/FasanTone.kt): fertiges PCM im
// Speicher, immer gleich laut, kein Dekodieren. Ohne Plugin (Tests, andere Systeme) bleibt der Systemklick.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import 'scope.dart';

/// One note of a tone: [hz] with relative [level], starting [startMs] after the beginning, own [decayMs].
class ToneNote {
  const ToneNote(this.hz, this.level, {this.startMs = 0, this.decayMs = 18});
  final double hz, level, startMs, decayMs;
}

/// Raw 16-bit little-endian mono PCM for [notes]. Each note has a 2 ms attack (no click) and an exponential decay; a
/// second partial an octave up is added at 30 % for a warmer, less „beepy“ sound.
Uint8List fasanPcm({required List<ToneNote> notes, required double ms, double level = 0.8, int rate = 22050}) {
  final n = (rate * ms / 1000).round();
  final pcm = ByteData(n * 2);
  final peak = notes.fold<double>(0, (a, x) => math.max(a, x.level));
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    var v = 0.0;
    for (final note in notes) {
      final tt = t - note.startMs / 1000;
      if (tt < 0) continue;
      final attack = math.min(1.0, tt / 0.002);
      final env = attack * math.exp(-tt * 1000 / note.decayMs);
      v += note.level * env * (math.sin(2 * math.pi * note.hz * tt) + 0.3 * math.sin(4 * math.pi * note.hz * tt));
    }
    // fade the last 3 ms to zero so the end cannot click
    final tail = math.min(1.0, (n - i) / (rate * 0.003));
    pcm.setInt16(i * 2, (v / (peak * 1.3) * tail * level * 32767).round().clamp(-32767, 32767), Endian.little);
  }
  return pcm.buffer.asUint8List();
}

/// WAV file around [fasanPcm]-style samples (kept for tests and other platforms).
Uint8List fasanTone({required List<(double, double)> partials, required double ms, double decayMs = 18, double level = 0.8, int rate = 22050}) {
  final data = fasanPcm(notes: [for (final (f, a) in partials) ToneNote(f, a, decayMs: decayMs)], ms: ms, level: level, rate: rate);
  final n = data.length ~/ 2;
  final out = ByteData(44 + n * 2);
  void ascii(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      out.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  out.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little);
  out.setUint16(22, 1, Endian.little);
  out.setUint32(24, rate, Endian.little);
  out.setUint32(28, rate * 2, Endian.little);
  out.setUint16(32, 2, Endian.little);
  out.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  out.setUint32(40, n * 2, Endian.little);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(44, 44 + n * 2, data);
  return bytes;
}

/// Plays the tap tones through the native AudioTrack. Falls back to the system click without the plugin.
abstract final class FasanSound {
  static const _ch = MethodChannel('app.fasan.ui/tone');
  static const int _rate = 22050;

  // Softer than the 0.1.24 sine blips: lower pitch, a little body, longer decay on the confirmation (Nutzer 03.11.: „ganz schlimm“).
  static final Map<FasanFeel, Uint8List> _pcm = {
    FasanFeel.tap: fasanPcm(notes: const [ToneNote(520, 1, decayMs: 16)], ms: 70, level: 0.9, rate: _rate),
    FasanFeel.snap: fasanPcm(notes: const [ToneNote(660, 1, decayMs: 14)], ms: 60, level: 0.9, rate: _rate),
    FasanFeel.confirm: fasanPcm(notes: const [ToneNote(523, 1, decayMs: 40), ToneNote(784, 0.9, startMs: 85, decayMs: 70)], ms: 260, level: 0.85, rate: _rate),
    FasanFeel.warn: fasanPcm(notes: const [ToneNote(247, 1, decayMs: 60), ToneNote(233, 0.8, startMs: 110, decayMs: 80)], ms: 320, level: 0.85, rate: _rate),
  };

  static final Set<FasanFeel> _loaded = {};
  static final Map<FasanFeel, int> _last = {};
  static int _lastAny = 0;

  /// What the log shows (Protokoll „darstellung.ton“).
  static String? lastError;
  static int plays = 0, failures = 0, skipped = 0;
  static String mode = 'audioTrack';

  /// Tests: skip the plugin and use the system click.
  @visibleForTesting
  static bool disabled = false;

  /// UI tones are part of the touch, not the music: moderate, and the same every time.
  static const double volume = 0.6;

  /// Plays a tone. Returns null when it went to the plugin, else the reason it did not (shown by the test button).
  /// Two plays of the same tone within 60 ms, or any two within 25 ms, count as one (one tap must make one sound).
  static Future<String?> play(FasanFeel feel) async {
    if (disabled) {
      await _fallback();
      return 'aus (Test)';
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_last[feel] ?? 0) < 60 || now - _lastAny < 25) {
      skipped++;
      return null;
    }
    _last[feel] = now;
    _lastAny = now;
    try {
      if (!_loaded.contains(feel)) {
        final ok = await _ch.invokeMethod<bool>('load', {'name': feel.name, 'pcm': _pcm[feel], 'rate': _rate});
        if (ok != true) throw StateError('Ton nicht geladen');
        _loaded.add(feel);
      }
      final ok = await _ch.invokeMethod<bool>('play', {'name': feel.name, 'volume': volume});
      if (ok != true) throw StateError('Ton nicht gespielt');
      plays++;
      failures = 0;
      lastError = null;
      return null;
    } catch (e) {
      lastError = '$e';
      failures++;
      _loaded.remove(feel);
      // after three failures in a row the plugin is not there (tests, other platforms): system click
      if (failures >= 3) await _fallback();
      return lastError;
    }
  }

  static Future<void> _fallback() => SystemSound.play(SystemSoundType.click);
}
