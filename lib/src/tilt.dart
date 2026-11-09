// fasan_ui – device tilt for the glass light edge (GESTALTUNG.md §5). MPL-2.0
//
// Channel name matches android/src/main/kotlin/app/fasan/ui/FasanTilt.kt (Game Rotation Vector, fallback accelerometer).
// The sensor runs only while at least one widget holds the tilt and the app is in the foreground
// (AppLifecycleState, api.flutter.dev/flutter/dart-ui/AppLifecycleState.html). Without sensor (tests, emulator without
// fusion) the value stays zero and the light keeps its resting direction (top left).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class FasanTilt extends ChangeNotifier with WidgetsBindingObserver {
  FasanTilt._();

  static final FasanTilt instance = FasanTilt._();
  static const _events = EventChannel('app.fasan.ui/tilt');

  /// Full deflection at ±20° from the resting pose (set: GESTALTUNG.md §5).
  static const double range = 20 * math.pi / 180;

  /// Low-pass factor per event (~30 Hz): 0.15 smooths hand tremor, still follows within ~0.2 s.
  static const double smoothing = 0.15;

  /// The resting pose follows slowly (time constant 4 s), so any way of holding the phone becomes "centre".
  static const double restSeconds = 4;

  Offset _value = Offset.zero;
  double? _basePitch, _baseRoll, _pitch, _roll, _lastMs;
  int _users = 0, _count = 0;
  DateTime _countStart = DateTime.now();
  StreamSubscription<Object?>? _sub;
  bool _observing = false, _foreground = true;

  /// x: roll (left/right), y: pitch (forward/back), each −1…1.
  Offset get value => _value;

  /// "game_rotation_vector", "accelerometer", "" (not started) or "none".
  String source = '';

  /// Events per second over the last second (effect test page).
  double rate = 0;

  void acquire() {
    _users++;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _update();
  }

  void release() {
    _users = math.max(0, _users - 1);
    _update();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _update();
  }

  void _update() {
    // No sensor channel in the browser (like power.dart): never listen there.
    final want = !kIsWeb && _users > 0 && _foreground && source != 'none';
    if (want && _sub == null) {
      _sub = _events.receiveBroadcastStream().listen(_onEvent, onError: (Object _) {
        source = 'none';
        _stop();
      });
    } else if (!want && _sub != null) {
      _stop();
    }
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _basePitch = _baseRoll = _lastMs = null;
    if (_value != Offset.zero) {
      _value = Offset.zero;
      notifyListeners();
    }
  }

  void _onEvent(Object? e) {
    if (e is! List || e.length < 4) return;
    final pitch = (e[0] as num).toDouble(), roll = (e[1] as num).toDouble(), ms = (e[2] as num).toDouble();
    source = e[3] as String;
    _count++;
    final now = DateTime.now();
    final span = now.difference(_countStart).inMilliseconds;
    if (span >= 1000) {
      rate = _count * 1000 / span;
      _count = 0;
      _countStart = now;
    }
    final dt = _lastMs == null ? 0.0 : ((ms - _lastMs!) / 1000).clamp(0.0, 0.5);
    _lastMs = ms;
    _basePitch ??= pitch;
    _baseRoll ??= roll;
    _pitch ??= pitch;
    _roll ??= roll;
    _pitch = _pitch! + (pitch - _pitch!) * smoothing;
    _roll = _roll! + (_angle(roll - _roll!)) * smoothing;
    final k = dt / restSeconds;
    _basePitch = _basePitch! + (_pitch! - _basePitch!) * k;
    _baseRoll = _baseRoll! + _angle(_roll! - _baseRoll!) * k;
    final v = Offset(
      (_angle(_roll! - _baseRoll!) / range).clamp(-1.0, 1.0),
      ((_pitch! - _basePitch!) / range).clamp(-1.0, 1.0),
    );
    if ((v - _value).distanceSquared > 1e-5) {
      _value = v;
      notifyListeners();
    }
  }

  /// Wraps an angle difference to −π…π (roll jumps at ±π when the phone is upside down).
  static double _angle(double a) => (a + math.pi) % (2 * math.pi) - math.pi;

  /// Tests and the effect test page: set a tilt without sensor.
  void simulate(Offset v) {
    _value = v;
    notifyListeners();
  }
}
