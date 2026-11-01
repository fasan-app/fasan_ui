// fasan_ui – user-facing appearance settings and their effective values. MPL-2.0
//
// Beschlüsse 01.11.2026 (fasan-app/Fasan ENTSCHEIDUNGEN.md): switchable styles, film effects subtle by default,
// three accents and three fonts, effects reduced on low battery / power saving, "Akku maximal", user keeps the choice.
import 'dart:convert';

import 'power.dart';

/// Visual styles. Only the look changes, never the functions (profiles change functions).
enum FasanStyle {
  /// Ruhe + Glas: calm surfaces, glass only for controls (default).
  calmGlass,

  /// Streng Braun/Bauhaus: grid, greys, one signal colour, no glass.
  braun,

  /// Volles Glas: more translucency, light reacts to touch.
  fullGlass,

  /// Filmisch: machine overlay (corner brackets, data labels, analysis sweeps).
  machine,

  /// Filmisch: Sci-Fi (cool, luminous lines).
  sciFi,

  /// Filmisch: Spionage (dark, red signal, typewriter-like labels).
  spy;

  bool get cinematic => this == machine || this == sciFi || this == spy;
  bool get glass => this == calmGlass || this == fullGlass;
}

enum FasanAccent { signal, cobalt, sage }

enum FasanFont { inter, system, geist }

/// How the app reacts to battery state.
enum FasanBatteryMode {
  /// Reduce effects when battery is low, power saving is on or the device is warm (default).
  auto,

  /// Always save as much as the app can ("Akku maximal").
  maximum,

  /// Never reduce automatically (the user decides).
  never,
}

/// Effective power level after combining the user's mode with the device state.
enum FasanPowerLevel { full, save, maximum }

/// Intensities 0–1 per film effect. Defaults are subtle (Beschluss 01.11.).
class FilmEffectSettings {
  const FilmEffectSettings({
    this.enabled = true,
    this.grain = 0.25,
    this.glow = 0.2,
    this.halation = 0.15,
    this.bleed = 0.1,
    this.weave = 0.15,
  });

  final bool enabled;
  final double grain, glow, halation, bleed, weave;

  bool get any => enabled && (grain > 0 || glow > 0 || halation > 0 || bleed > 0 || weave > 0);

  FilmEffectSettings copyWith({bool? enabled, double? grain, double? glow, double? halation, double? bleed, double? weave}) =>
      FilmEffectSettings(
        enabled: enabled ?? this.enabled,
        grain: grain ?? this.grain,
        glow: glow ?? this.glow,
        halation: halation ?? this.halation,
        bleed: bleed ?? this.bleed,
        weave: weave ?? this.weave,
      );

  Map<String, Object> toJson() =>
      {'enabled': enabled, 'grain': grain, 'glow': glow, 'halation': halation, 'bleed': bleed, 'weave': weave};

  static FilmEffectSettings fromJson(Map<String, Object?> j) {
    double d(String k, double v) => (j[k] as num?)?.toDouble().clamp(0.0, 1.0) ?? v;
    const z = FilmEffectSettings();
    return FilmEffectSettings(
      enabled: j['enabled'] as bool? ?? true,
      grain: d('grain', z.grain),
      glow: d('glow', z.glow),
      halation: d('halation', z.halation),
      bleed: d('bleed', z.bleed),
      weave: d('weave', z.weave),
    );
  }
}

enum FasanThemeMode { system, light, dark }

/// All appearance settings. Immutable; change with [copyWith].
class FasanSettings {
  const FasanSettings({
    this.style = FasanStyle.calmGlass,
    this.accent = FasanAccent.cobalt,
    this.font = FasanFont.inter,
    this.themeMode = FasanThemeMode.system,
    this.effects = const FilmEffectSettings(),
    this.battery = FasanBatteryMode.auto,
    this.reduceMotion = false,
    this.haptics = true,
    this.simpleProfile = false,
  });

  final FasanStyle style;
  final FasanAccent accent;
  final FasanFont font;
  final FasanThemeMode themeMode;
  final FilmEffectSettings effects;
  final FasanBatteryMode battery;

  /// App setting "Weniger Bewegung"; the system option "Animationen entfernen" applies in addition.
  final bool reduceMotion;
  final bool haptics;

  /// Profile "Einfach": larger tap areas (60 dp) and text.
  final bool simpleProfile;

  double get minTap => simpleProfile ? 60 : 48;

  FasanSettings copyWith({
    FasanStyle? style,
    FasanAccent? accent,
    FasanFont? font,
    FasanThemeMode? themeMode,
    FilmEffectSettings? effects,
    FasanBatteryMode? battery,
    bool? reduceMotion,
    bool? haptics,
    bool? simpleProfile,
  }) =>
      FasanSettings(
        style: style ?? this.style,
        accent: accent ?? this.accent,
        font: font ?? this.font,
        themeMode: themeMode ?? this.themeMode,
        effects: effects ?? this.effects,
        battery: battery ?? this.battery,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        haptics: haptics ?? this.haptics,
        simpleProfile: simpleProfile ?? this.simpleProfile,
      );

  /// Combines the user's battery mode with the device state.
  /// "Sparen" when battery ≤ 20 % (not charging), power saving is on, or thermal status ≥ MODERATE (2).
  /// Thresholds: own choice, documented in docs/recherche/2026-11-01-design-grundlagen.md.
  FasanPowerLevel powerLevel(FasanPowerState p) {
    switch (battery) {
      case FasanBatteryMode.maximum:
        return FasanPowerLevel.maximum;
      case FasanBatteryMode.never:
        return FasanPowerLevel.full;
      case FasanBatteryMode.auto:
        final low = p.battery != null && p.battery! <= 20 && !p.charging;
        return (low || p.powerSave || p.thermal >= 2) ? FasanPowerLevel.save : FasanPowerLevel.full;
    }
  }

  String encode() => jsonEncode({
        'style': style.name,
        'accent': accent.name,
        'font': font.name,
        'themeMode': themeMode.name,
        'effects': effects.toJson(),
        'battery': battery.name,
        'reduceMotion': reduceMotion,
        'haptics': haptics,
        'simpleProfile': simpleProfile,
      });

  static FasanSettings decode(String? s) {
    if (s == null || s.isEmpty) return const FasanSettings();
    try {
      final j = jsonDecode(s) as Map<String, Object?>;
      T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
          values.firstWhere((v) => v.name == name, orElse: () => fallback);
      return FasanSettings(
        style: pick(FasanStyle.values, j['style'], FasanStyle.calmGlass),
        accent: pick(FasanAccent.values, j['accent'], FasanAccent.cobalt),
        font: pick(FasanFont.values, j['font'], FasanFont.inter),
        themeMode: pick(FasanThemeMode.values, j['themeMode'], FasanThemeMode.system),
        effects: FilmEffectSettings.fromJson((j['effects'] as Map?)?.cast<String, Object?>() ?? const {}),
        battery: pick(FasanBatteryMode.values, j['battery'], FasanBatteryMode.auto),
        reduceMotion: j['reduceMotion'] as bool? ?? false,
        haptics: j['haptics'] as bool? ?? true,
        simpleProfile: j['simpleProfile'] as bool? ?? false,
      );
    } catch (_) {
      return const FasanSettings();
    }
  }
}
