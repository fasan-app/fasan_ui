// fasan_ui – controller, scope, motion and haptics. MPL-2.0
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Haptics via Flutter's HapticFeedback (api.flutter.dev/flutter/services/HapticFeedback-class.html).
/// Standard on (Beschluss 01.11.), switchable in the settings.
class FasanHaptics {
  const FasanHaptics._(this.enabled);

  final bool enabled;

  static FasanHaptics of(BuildContext context) => FasanHaptics._(FasanScope.maybeOf(context)?.settings.haptics ?? true);

  Future<void> tap() => enabled ? HapticFeedback.selectionClick() : Future.value();
  Future<void> confirm() => enabled ? HapticFeedback.lightImpact() : Future.value();
  Future<void> snap() => enabled ? HapticFeedback.mediumImpact() : Future.value();
  Future<void> warn() => enabled ? HapticFeedback.heavyImpact() : Future.value();
}
