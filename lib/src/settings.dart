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

/// Where grain and weave apply (GESTALTUNG.md §2): only the ground behind content (default) or the whole picture.
enum FasanFilmLayer { ground, whole }

/// Old-film look (flicker, dust, scratches, vignette, warm cast): auto = on only in the cinematic styles (Nutzer 02.11.).
enum FasanOldFilm { auto, on, off }

/// Film effects. Intensities 0–1. Defaults are noticeable but calm (Nutzer 02.11.: „subtil ist … überhaupt nicht merkbar“).
class FilmEffectSettings {
  const FilmEffectSettings({
    this.enabled = true,
    this.grain = 0.22,
    this.grainSize = 0.12,
    this.grainSpeed = 1.0,
    this.grainSoft = 0.5,
    this.grainClump = 0.25,
    this.grainChroma = 0.0,
    this.oldFilm = FasanOldFilm.auto,
    this.flicker = 0.5,
    this.dust = 0.35,
    this.scratches = 0.25,
    this.vignette = 0.4,
    this.warmth = 0.3,
    this.glow = 0.5,
    this.halation = 0.35,
    this.bleed = 0.25,
    this.weave = 0.4,
    this.layer = FasanFilmLayer.ground,
    this.gradient = true,
    this.lightSweep = true,
    this.tilt = true,
  });

  final bool enabled;

  /// grain: strength. grainSize: 0 → 0.6 px … 1 → 4 px. grainSpeed: 0 = still … 1 = 24 grain frames per second.
  /// grainSoft: hard cells … soft blobs. grainClump: share of coarser clumps. grainChroma: mono film … colour noise.
  final double grain, grainSize, grainSpeed, grainSoft, grainClump, grainChroma, glow, halation, bleed, weave;

  /// Old-film switch and amounts (0–1) of its parts.
  final FasanOldFilm oldFilm;
  final double flicker, dust, scratches, vignette, warmth;
  final FasanFilmLayer layer;

  /// Animated colour field behind content, wandering light band, light edge following the device tilt.
  final bool gradient, lightSweep, tilt;

  /// Grain cell in canvas units.
  double get grainPx => 0.6 + grainSize * 3.4;

  /// Grain frames per second (a new, independent grain image each frame).
  double get grainFps => grainSpeed * 24;

  /// Old film shown for a style.
  bool oldFilmFor(FasanStyle style) => oldFilm == FasanOldFilm.on || (oldFilm == FasanOldFilm.auto && style.cinematic);

  bool get any => enabled && (grain > 0 || glow > 0 || halation > 0 || bleed > 0 || weave > 0 || gradient || lightSweep || tilt);

  FilmEffectSettings copyWith({
    bool? enabled,
    double? grain,
    double? grainSize,
    double? grainSpeed,
    double? grainSoft,
    double? grainClump,
    double? grainChroma,
    FasanOldFilm? oldFilm,
    double? flicker,
    double? dust,
    double? scratches,
    double? vignette,
    double? warmth,
    double? glow,
    double? halation,
    double? bleed,
    double? weave,
    FasanFilmLayer? layer,
    bool? gradient,
    bool? lightSweep,
    bool? tilt,
  }) =>
      FilmEffectSettings(
        enabled: enabled ?? this.enabled,
        grain: grain ?? this.grain,
        grainSize: grainSize ?? this.grainSize,
        grainSpeed: grainSpeed ?? this.grainSpeed,
        grainSoft: grainSoft ?? this.grainSoft,
        grainClump: grainClump ?? this.grainClump,
        grainChroma: grainChroma ?? this.grainChroma,
        oldFilm: oldFilm ?? this.oldFilm,
        flicker: flicker ?? this.flicker,
        dust: dust ?? this.dust,
        scratches: scratches ?? this.scratches,
        vignette: vignette ?? this.vignette,
        warmth: warmth ?? this.warmth,
        glow: glow ?? this.glow,
        halation: halation ?? this.halation,
        bleed: bleed ?? this.bleed,
        weave: weave ?? this.weave,
        layer: layer ?? this.layer,
        gradient: gradient ?? this.gradient,
        lightSweep: lightSweep ?? this.lightSweep,
        tilt: tilt ?? this.tilt,
      );

  Map<String, Object> toJson() => {
        'v': 3,
        'enabled': enabled,
        'grain': grain,
        'grainSize': grainSize,
        'grainSpeed': grainSpeed,
        'grainSoft': grainSoft,
        'grainClump': grainClump,
        'grainChroma': grainChroma,
        'oldFilm': oldFilm.name,
        'flicker': flicker,
        'dust': dust,
        'scratches': scratches,
        'vignette': vignette,
        'warmth': warmth,
        'glow': glow,
        'halation': halation,
        'bleed': bleed,
        'weave': weave,
        'layer': layer.name,
        'gradient': gradient,
        'lightSweep': lightSweep,
        'tilt': tilt,
      };

  static FilmEffectSettings fromJson(Map<String, Object?> j) {
    const z = FilmEffectSettings();
    // Older versions stored defaults the user never chose (v1: invisible grain; v2 in 0.1.13: grain far too coarse and
    // strong, emulator pictures 02.11.). Start from the current defaults and keep only an explicit „aus“.
    if (j['v'] != 3) return FilmEffectSettings(enabled: j['enabled'] as bool? ?? true);
    double d(String k, double v) => (j[k] as num?)?.toDouble().clamp(0.0, 1.0) ?? v;
    bool b(String k, bool v) => j[k] as bool? ?? v;
    return FilmEffectSettings(
      enabled: b('enabled', true),
      grain: d('grain', z.grain),
      grainSize: d('grainSize', z.grainSize),
      grainSpeed: d('grainSpeed', z.grainSpeed),
      grainSoft: d('grainSoft', z.grainSoft),
      grainClump: d('grainClump', z.grainClump),
      grainChroma: d('grainChroma', z.grainChroma),
      oldFilm: FasanOldFilm.values.firstWhere((v) => v.name == j['oldFilm'], orElse: () => z.oldFilm),
      flicker: d('flicker', z.flicker),
      dust: d('dust', z.dust),
      scratches: d('scratches', z.scratches),
      vignette: d('vignette', z.vignette),
      warmth: d('warmth', z.warmth),
      glow: d('glow', z.glow),
      halation: d('halation', z.halation),
      bleed: d('bleed', z.bleed),
      weave: d('weave', z.weave),
      layer: FasanFilmLayer.values.firstWhere((v) => v.name == j['layer'], orElse: () => z.layer),
      gradient: b('gradient', z.gradient),
      lightSweep: b('lightSweep', z.lightSweep),
      tilt: b('tilt', z.tilt),
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
    this.reduceTransparency = false,
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

  /// App setting „Transparenz reduzieren“: glass becomes an opaque surface (Apple: Reduce Transparency, Session 219).
  final bool reduceTransparency;

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
    bool? reduceTransparency,
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
        reduceTransparency: reduceTransparency ?? this.reduceTransparency,
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
        'reduceTransparency': reduceTransparency,
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
        reduceTransparency: j['reduceTransparency'] as bool? ?? false,
      );
    } catch (_) {
      return const FasanSettings();
    }
  }
}
