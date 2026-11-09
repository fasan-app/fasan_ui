// fasan_ui – design tokens shared by all Fasan apps. MPL-2.0
//
// Values follow fasan-app/Fasan GRUNDSAETZE.md (motion table) and ENTSCHEIDUNGEN.md
// (01.11.2026: tap area ≥ 48 dp, profile "Einfach" 60 dp).
import 'package:flutter/animation.dart';

/// Spacing scale (logical pixels). A 4-pt grid keeps layouts calm (Rams: "as little design as possible").
abstract final class FasanSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii. Glass styles use the larger, continuous-looking radii; Braun uses small ones.
abstract final class FasanRadius {
  static const double s = 8;
  static const double m = 14;
  static const double l = 22;
  static const double xl = 28;
}

/// Minimum tap areas (Beschluss 01.11.2026: 48 dp, profile "Einfach" 60 dp; Parhi, Karlson & Bederson 2006).
abstract final class FasanTap {
  static const double min = 48;
  static const double simple = 60;
}

/// Motion tokens from GRUNDSAETZE.md. Durations become zero when motion is off (see FasanMotion).
abstract final class FasanDurations {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration long = Duration(milliseconds: 320);
}

abstract final class FasanCurves {
  static const Curve short = Curves.easeOutCubic;
  static const Curve medium = Curves.easeInOutCubic;
  static const Curve long = Curves.easeInOutCubic;
}
