// fasan_ui – colours, typography and ThemeData per style. MPL-2.0
//
// Contrast: text on surfaces and onAccent on accent are checked ≥ 4.5:1 (WCAG 2.x AA) in test/contrast_test.dart.

import 'package:flutter/material.dart';

import 'settings.dart';
import 'tokens.dart';

/// Style-specific values that Material's ColorScheme has no slot for. Read with `FasanLook.of(context)`.
@immutable
class FasanLook extends ThemeExtension<FasanLook> {
  const FasanLook({
    required this.style,
    required this.brightness,
    required this.level,
    required this.effects,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.textMuted,
    required this.hairline,
    required this.accent,
    required this.onAccent,
    required this.line,
    required this.glassTint,
    required this.glassBlur,
    required this.radius,
    required this.minTap,
    required this.fontFamily,
    required this.monoFamily,
    required this.fontPackage,
  });

  final FasanStyle style;
  final Brightness brightness;
  final FasanPowerLevel level;
  final FilmEffectSettings effects;
  final Color background, surface, surfaceAlt, text, textMuted, hairline, accent, onAccent;

  /// Colour for overlay lines (machine brackets, sci-fi rules).
  final Color line;

  /// Tint and blur sigma for glass; blur 0 = opaque panel (Braun, or saving power).
  final Color glassTint;
  final double glassBlur;
  final double radius;
  final double minTap;
  final String? fontFamily, monoFamily, fontPackage;

  bool get saving => level != FasanPowerLevel.full;

  /// Film effects actually shown: off while saving power (Beschluss 01.11.).
  bool get effectsActive => effects.any && level == FasanPowerLevel.full;

  static FasanLook of(BuildContext context) =>
      Theme.of(context).extension<FasanLook>() ?? FasanThemes.look(const FasanSettings(), Brightness.light, FasanPowerLevel.full);

  TextStyle mono(double size, {FontWeight weight = FontWeight.w400, Color? color}) => TextStyle(
        fontFamily: monoFamily,
        package: fontPackage,
        fontSize: size,
        fontWeight: weight,
        color: color ?? textMuted,
        letterSpacing: 0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  FasanLook copyWith({FasanPowerLevel? level, FilmEffectSettings? effects}) => FasanLook(
        style: style,
        brightness: brightness,
        level: level ?? this.level,
        effects: effects ?? this.effects,
        background: background,
        surface: surface,
        surfaceAlt: surfaceAlt,
        text: text,
        textMuted: textMuted,
        hairline: hairline,
        accent: accent,
        onAccent: onAccent,
        line: line,
        glassTint: glassTint,
        glassBlur: glassBlur,
        radius: radius,
        minTap: minTap,
        fontFamily: fontFamily,
        monoFamily: monoFamily,
        fontPackage: fontPackage,
      );

  @override
  FasanLook lerp(covariant FasanLook? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return FasanLook(
      style: t < 0.5 ? style : other.style,
      brightness: t < 0.5 ? brightness : other.brightness,
      level: t < 0.5 ? level : other.level,
      effects: t < 0.5 ? effects : other.effects,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      hairline: c(hairline, other.hairline),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      line: c(line, other.line),
      glassTint: c(glassTint, other.glassTint),
      glassBlur: glassBlur + (other.glassBlur - glassBlur) * t,
      radius: radius + (other.radius - radius) * t,
      minTap: t < 0.5 ? minTap : other.minTap,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      monoFamily: t < 0.5 ? monoFamily : other.monoFamily,
      fontPackage: t < 0.5 ? fontPackage : other.fontPackage,
    );
  }
}

/// Builds looks and ThemeData. All colours live here so styles stay comparable.
abstract final class FasanThemes {
  static const _pkg = 'fasan_ui';

  /// Accent fills. Light values are dark enough for white text, dark values light enough for near-black text.
  static Color accent(FasanAccent a, Brightness b) {
    final dark = b == Brightness.dark;
    switch (a) {
      case FasanAccent.signal:
        return dark ? const Color(0xFFFF8A4C) : const Color(0xFFC2410C);
      case FasanAccent.cobalt:
        return dark ? const Color(0xFF8AA4FF) : const Color(0xFF2B54D6);
      case FasanAccent.sage:
        return dark ? const Color(0xFF5CCFA5) : const Color(0xFF26745C);
    }
  }

  static FasanLook look(FasanSettings s, Brightness b, FasanPowerLevel level) {
    // "Akku maximal" prefers dark surfaces: OLED panels draw less power for dark pixels (Apple WWDC22 10083;
    // for Android not measured here – nicht geprüft). The user's explicit light choice still wins.
    final dark = b == Brightness.dark;
    final a = accent(s.accent, b);
    final onA = dark ? const Color(0xFF0B0B0C) : Colors.white;
    final (String? family, String mono, String pkg) = switch (s.font) {
      FasanFont.inter => ('FasanInter', 'FasanGeistMono', _pkg),
      FasanFont.geist => ('FasanGeist', 'FasanGeistMono', _pkg),
      FasanFont.system => (null, 'FasanGeistMono', _pkg),
    };
    // System font: fontFamily null uses the platform default (Roboto/Google Sans on Android).
    final blurOk = level == FasanPowerLevel.full;
    Color tintFor(Color base, double o) => base.withValues(alpha: blurOk ? o : 1);
    switch (s.style) {
      case FasanStyle.calmGlass:
      case FasanStyle.fullGlass:
        final full = s.style == FasanStyle.fullGlass;
        final bg = dark ? const Color(0xFF0B0B0C) : const Color(0xFFF4F4F1);
        final surf = dark ? const Color(0xFF17171A) : Colors.white;
        return FasanLook(
          style: s.style, brightness: b, level: level, effects: s.effects,
          background: bg, surface: surf,
          surfaceAlt: dark ? const Color(0xFF212125) : const Color(0xFFECECE8),
          text: dark ? const Color(0xFFF2F2F0) : const Color(0xFF111112),
          textMuted: dark ? const Color(0xFFA6A6A8) : const Color(0xFF5E5E62),
          hairline: dark ? const Color(0x24FFFFFF) : const Color(0x1A000000),
          accent: a, onAccent: onA,
          line: dark ? const Color(0x55FFFFFF) : const Color(0x44000000),
          glassTint: tintFor(dark ? const Color(0xFF1C1C20) : const Color(0xFFFFFFFF), full ? 0.42 : 0.68),
          glassBlur: blurOk ? (full ? 28 : 18) : 0,
          radius: full ? FasanRadius.xl : FasanRadius.l,
          minTap: s.minTap, fontFamily: family, monoFamily: mono, fontPackage: pkg,
        );
      case FasanStyle.braun:
        return FasanLook(
          style: s.style, brightness: b, level: level, effects: s.effects,
          background: dark ? const Color(0xFF1B1B1A) : const Color(0xFFE9E8E3),
          surface: dark ? const Color(0xFF262624) : const Color(0xFFF6F5F0),
          surfaceAlt: dark ? const Color(0xFF30302D) : const Color(0xFFDDDCD6),
          text: dark ? const Color(0xFFEDECE6) : const Color(0xFF1A1A19),
          textMuted: dark ? const Color(0xFFABAAA3) : const Color(0xFF5A5954),
          hairline: dark ? const Color(0xFF3B3B38) : const Color(0xFFC6C5BE),
          accent: a, onAccent: onA,
          line: dark ? const Color(0xFF4A4A46) : const Color(0xFFB5B4AD),
          glassTint: dark ? const Color(0xFF262624) : const Color(0xFFF6F5F0),
          glassBlur: 0,
          radius: FasanRadius.s,
          minTap: s.minTap, fontFamily: family, monoFamily: mono, fontPackage: pkg,
        );
      case FasanStyle.machine:
      case FasanStyle.sciFi:
      case FasanStyle.spy:
        // Cinematic styles: serious, high contrast, line work instead of decoration. Light variants exist for text.
        final (Color bgD, Color sfD, Color txD, Color lnD, Color bgL, Color sfL, Color txL, Color lnL) = switch (s.style) {
          FasanStyle.machine => (
              const Color(0xFF0D0F10), const Color(0xFF161A1C), const Color(0xFFE4E7E1), const Color(0xFF9FB3A6),
              const Color(0xFFEEF0EC), const Color(0xFFFAFBF9), const Color(0xFF131615), const Color(0xFF52665A)),
          FasanStyle.sciFi => (
              const Color(0xFF050912), const Color(0xFF0C1322), const Color(0xFFDDE8FF), const Color(0xFF6FC7FF),
              const Color(0xFFEFF3FA), const Color(0xFFFFFFFF), const Color(0xFF0C1424), const Color(0xFF2A6FA8)),
          _ => (
              const Color(0xFF0C0A09), const Color(0xFF171311), const Color(0xFFECE5DE), const Color(0xFFB8463C),
              const Color(0xFFF1EDE8), const Color(0xFFFBF9F6), const Color(0xFF1A1513), const Color(0xFF9A3229)),
        };
        return FasanLook(
          style: s.style, brightness: b, level: level, effects: s.effects,
          background: dark ? bgD : bgL,
          surface: dark ? sfD : sfL,
          surfaceAlt: Color.lerp(dark ? sfD : sfL, dark ? lnD : lnL, 0.08)!,
          text: dark ? txD : txL,
          textMuted: Color.lerp(dark ? txD : txL, dark ? bgD : bgL, 0.32)!,
          hairline: (dark ? lnD : lnL).withValues(alpha: 0.28),
          accent: a, onAccent: onA,
          line: dark ? lnD : lnL,
          glassTint: tintFor(dark ? sfD : sfL, 0.78),
          glassBlur: blurOk ? 12 : 0,
          radius: FasanRadius.s,
          minTap: s.minTap, fontFamily: family, monoFamily: mono, fontPackage: pkg,
        );
    }
  }

  static ThemeData theme(FasanSettings s, Brightness b, FasanPowerLevel level) {
    final l = look(s, b, level);
    final scheme = ColorScheme(
      brightness: b,
      primary: l.accent,
      onPrimary: l.onAccent,
      secondary: l.accent,
      onSecondary: l.onAccent,
      error: b == Brightness.dark ? const Color(0xFFFF8A80) : const Color(0xFFB3261E),
      onError: b == Brightness.dark ? const Color(0xFF2B0B08) : Colors.white,
      surface: l.surface,
      onSurface: l.text,
      onSurfaceVariant: l.textMuted,
      outline: l.hairline,
      outlineVariant: l.hairline,
      surfaceContainerHighest: l.surfaceAlt,
    );
    final scale = s.simpleProfile ? 1.12 : 1.0;
    // Package fonts are addressed as 'packages/<package>/<family>' (api.flutter.dev, TextStyle "Font family" / package).
    final family = l.fontFamily == null ? null : 'packages/${l.fontPackage}/${l.fontFamily}';
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: l.background,
      fontFamily: family,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: l.hairline,
      extensions: [l],
    );
    TextStyle t(double size, FontWeight w, {double h = 1.3, double ls = 0, Color? c}) =>
        // fontFamily must be repeated: these styles replace the ones ThemeData(fontFamily:) filled in, and a new
        // TextStyle without a family falls back to the platform font (bug in 0.1: Inter/Geist never showed).
        TextStyle(fontFamily: family, fontSize: size * scale, fontWeight: w, height: h, letterSpacing: ls, color: c ?? l.text);
    final cine = s.style.cinematic;
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: t(34, FontWeight.w600, h: 1.1, ls: -0.6),
        headlineSmall: t(24, FontWeight.w600, h: 1.15, ls: -0.3),
        titleLarge: t(20, FontWeight.w600, h: 1.2, ls: -0.2),
        titleMedium: t(16, FontWeight.w600, ls: cine ? 0.4 : 0),
        bodyLarge: t(16, FontWeight.w400, h: 1.4),
        bodyMedium: t(14, FontWeight.w400, h: 1.4),
        bodySmall: t(12.5, FontWeight.w400, c: l.textMuted),
        labelLarge: t(15, FontWeight.w600, ls: cine ? 1.0 : 0.1),
        labelMedium: t(13, FontWeight.w500, c: l.textMuted, ls: cine ? 0.8 : 0.1),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: l.accent,
        thumbColor: l.accent,
        inactiveTrackColor: l.hairline,
        overlayColor: l.accent.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? l.onAccent : l.textMuted),
        trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? l.accent : l.surfaceAlt),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: l.surfaceAlt,
        // Not OutlineInputBorder: with an outline the floating label is centred on the top edge, half outside the
        // filled field, and gets clipped at the top of a list (Flutter input_decorator.dart, outlinedFloatingY).
        border: UnderlineInputBorder(borderRadius: BorderRadius.circular(l.radius * 0.6), borderSide: BorderSide.none),
        enabledBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(l.radius * 0.6), borderSide: BorderSide.none),
        // Visible focus (WCAG 2.4.7): accent line at the bottom edge.
        focusedBorder: UnderlineInputBorder(borderRadius: BorderRadius.circular(l.radius * 0.6), borderSide: BorderSide(color: l.accent, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: l.background,
        foregroundColor: l.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t(20, FontWeight.w600, ls: -0.2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: l.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(l.radius))),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: l.text, contentTextStyle: t(14, FontWeight.w500, c: l.background)),
      iconTheme: IconThemeData(color: l.text, size: 22),
    );
  }
}
