// fasan_ui – controller, scope, motion and haptics. MPL-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'power.dart';
import 'settings.dart';
import 'theme.dart';
import 'tokens.dart';

/// Holds the settings and the device power state. Apps persist [settings] themselves (e.g. with
/// shared_preferences) via [onChanged]; fasan_ui does not touch storage.
class FasanController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  FasanController({FasanSettings settings = const FasanSettings(), this.onChanged}) : _settings = settings;

  FasanSettings _settings;
  FasanPowerState _power = const FasanPowerState();
  StreamSubscription<FasanPowerState>? _sub;
  final void Function(FasanSettings)? onChanged;

  FasanSettings get settings => _settings;
  FasanPowerState get power => _power;
  FasanPowerLevel get level => _settings.powerLevel(_power);

  set settings(FasanSettings s) {
    _settings = s;
    onChanged?.call(s);
    notifyListeners();
  }

  void update(FasanSettings Function(FasanSettings) f) => settings = f(_settings);

  /// Starts listening to battery, power saving and thermal status (Android). Safe to call where unsupported.
  Future<void> start() async {
    _power = await FasanPower.current();
    notifyListeners();
    _sub ??= FasanPower.changes().listen((p) {
      if (p != _power) {
        _power = p;
        notifyListeners();
      }
    });
  }

  /// For tests and the gallery: simulate a device state.
  void debugSetPower(FasanPowerState p) {
    _power = p;
    notifyListeners();
  }

  ThemeData theme(Brightness b) => FasanThemes.theme(_settings, _effectiveBrightness(b), level);

  /// "Akku maximal" switches "System" to dark (the user's explicit light choice is kept).
  Brightness _effectiveBrightness(Brightness b) =>
      level == FasanPowerLevel.maximum && _settings.themeMode == FasanThemeMode.system ? Brightness.dark : b;

  ThemeMode get themeMode => switch (_settings.themeMode) {
        FasanThemeMode.system => level == FasanPowerLevel.maximum ? ThemeMode.dark : ThemeMode.system,
        FasanThemeMode.light => ThemeMode.light,
        FasanThemeMode.dark => ThemeMode.dark,
      };

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class FasanScope extends InheritedNotifier<FasanController> {
  const FasanScope({super.key, required FasanController controller, required super.child}) : super(notifier: controller);

  static FasanController of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<FasanScope>();
    assert(s != null, 'FasanScope fehlt über diesem Widget');
    return s!.notifier!;
  }

  static FasanController? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FasanScope>()?.notifier;
}

/// Motion that follows the system option "Animationen entfernen" (MediaQuery.disableAnimations, api.flutter.dev)
/// and the app setting "Weniger Bewegung". Off → durations are zero and springs settle immediately.
class FasanMotion {
  const FasanMotion._(this.enabled, this.fast);

  final bool enabled;

  /// "Akku maximal": shortest animations.
  final bool fast;

  static FasanMotion of(BuildContext context) {
    final c = FasanScope.maybeOf(context);
    final system = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final app = c?.settings.reduceMotion ?? false;
    return FasanMotion._(!system && !app, c?.level == FasanPowerLevel.maximum);
  }

  Duration get short => _d(FasanDurations.short);
  Duration get medium => _d(FasanDurations.medium);
  Duration get long => _d(FasanDurations.long);

  Duration _d(Duration d) => !enabled ? Duration.zero : (fast ? d * 0.6 : d);

  /// Spring for gesture-driven motion: critically damped feel without overshoot that distracts.
  /// Values chosen by eye (nicht geprüft gegen Studien); damping ratio < 1 gives a slight, calm settle.
  SpringDescription get spring => SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.86);

  /// Bouncier spring for confirmations (a tap that "lands").
  SpringDescription get springSoft => SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: 0.72);
}

/// Strength of one feedback.
enum FasanFeel { tap, confirm, snap, warn }

/// Haptics and a small click. Two ways to vibrate: Flutter's `HapticFeedback` (Android touch feedback, follows the system
/// setting; api.flutter.dev/flutter/services/HapticFeedback-class.html) and the Vibrator service through the `vibration`
/// plugin (`hapticsDirect`, needs VIBRATE in the app manifest). Standard on (Beschluss 01.11.), switchable in the settings.
/// The click is `SystemSound` (api.flutter.dev/flutter/services/SystemSoundType.html): on Android only `click`, played
/// while the system's touch sounds are on, so the silent mode silences it (nicht auf One UI geprüft).
class FasanHaptics {
  const FasanHaptics._(this.enabled, this.direct, this.sound);

  final bool enabled, direct, sound;

  static FasanHaptics of(BuildContext context) {
    final s = FasanScope.maybeOf(context)?.settings;
    return FasanHaptics._(s?.haptics ?? true, s?.hapticsDirect ?? true, s?.sound ?? true);
  }

  /// For the settings page: play one way regardless of the switches.
  static Future<void> probeSystem(FasanFeel f) => _system(f);
  static Future<void> probeDirect(FasanFeel f) => _direct(f);
  static Future<void> probeSound() => SystemSound.play(SystemSoundType.click);

  Future<void> tap() => _go(FasanFeel.tap, click: true);
  Future<void> confirm() => _go(FasanFeel.confirm);
  Future<void> snap() => _go(FasanFeel.snap, click: true);
  Future<void> warn() => _go(FasanFeel.warn);

  Future<void> _go(FasanFeel f, {bool click = false}) async {
    if (click && sound) unawaited(SystemSound.play(SystemSoundType.click));
    if (!enabled) return;
    if (direct) {
      try {
        await _direct(f);
        return;
      } catch (_) {
        // no vibrator plugin (tests, other platforms): fall back to the system feedback
      }
    }
    await _system(f);
  }

  static Future<void> _system(FasanFeel f) => switch (f) {
        FasanFeel.tap => HapticFeedback.selectionClick(),
        FasanFeel.confirm => HapticFeedback.lightImpact(),
        FasanFeel.snap => HapticFeedback.mediumImpact(),
        FasanFeel.warn => HapticFeedback.heavyImpact(),
      };

  static bool? _hasVibrator;

  /// Short pulses; Android ignores very short ones on some motors, so the lightest is 15 ms.
  static Future<void> _direct(FasanFeel f) async {
    _hasVibrator ??= await Vibration.hasVibrator();
    if (_hasVibrator != true) throw StateError('no vibrator');
    switch (f) {
      case FasanFeel.tap:
        await Vibration.vibrate(duration: 15, amplitude: 90);
      case FasanFeel.confirm:
        await Vibration.vibrate(duration: 30, amplitude: 140);
      case FasanFeel.snap:
        await Vibration.vibrate(duration: 45, amplitude: 190);
      case FasanFeel.warn:
        await Vibration.vibrate(pattern: [0, 60, 50, 60], intensities: [0, 220, 0, 220]);
    }
  }
}
