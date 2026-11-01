// fasan_ui – device power state (battery, power saving, thermal) from the Android plugin. MPL-2.0
//
// Channel names match android/src/main/kotlin/app/fasan/ui/FasanUiPlugin.kt.
// Where the plugin is missing (tests, web, other platforms) the state stays "unknown / not saving".
import 'dart:async';

import 'package:flutter/services.dart';

class FasanPowerState {
  const FasanPowerState({this.battery, this.charging = false, this.powerSave = false, this.thermal = -1});

  /// Battery level 0–100, or null if unknown.
  final int? battery;
  final bool charging;

  /// PowerManager.isPowerSaveMode().
  final bool powerSave;

  /// PowerManager.THERMAL_STATUS_* (0 none … 6 shutdown), −1 unknown.
  final int thermal;

  static FasanPowerState fromMap(Object? m) {
    if (m is! Map) return const FasanPowerState();
    return FasanPowerState(
      battery: (m['battery'] as num?)?.toInt(),
      charging: m['charging'] == true,
      powerSave: m['powerSave'] == true,
      thermal: (m['thermal'] as num?)?.toInt() ?? -1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FasanPowerState &&
      other.battery == battery &&
      other.charging == charging &&
      other.powerSave == powerSave &&
      other.thermal == thermal;

  @override
  int get hashCode => Object.hash(battery, charging, powerSave, thermal);
}

class FasanPower {
  FasanPower._();

  static const _methods = MethodChannel('app.fasan.ui/power');
  static const _events = EventChannel('app.fasan.ui/power/events');

  static Future<FasanPowerState> current() async {
    try {
      return FasanPowerState.fromMap(await _methods.invokeMethod<Object>('state'));
    } on MissingPluginException {
      return const FasanPowerState();
    } on PlatformException {
      return const FasanPowerState();
    }
  }

  /// Changes of battery, power saving and thermal status. Empty stream where unsupported.
  static Stream<FasanPowerState> changes() {
    return _events.receiveBroadcastStream().map(FasanPowerState.fromMap).handleError((Object _) {});
  }

  /// Opens the system battery saver settings ("Akku maximal" can only suggest it; apps may not switch it).
  static Future<bool> openBatterySaverSettings() async {
    try {
      return await _methods.invokeMethod<bool>('openBatterySaver') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
