// fasan_ui – layered drop shadows for a stronger 3D feel; the shadow turns with the device tilt. MPL-2.0
//
// Nutzer 03.11.: „Schlagschatten auf diversen Elementen für einen stärkeren 3D-Effekt“, Licht folgt der Neigung.
// Several shadows of different size look like one soft object shadow (one big shadow looks like a blur). The light
// comes from the top left at rest; tilt turns it like in FasanGlass (same angle formula), so glass and shadows agree.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../effects/backdrop.dart';
import '../tilt.dart';

abstract final class FasanShadows {
  /// [level] 1 chips and small buttons, 2 cards, 3 floating bars and the plus button. [tint] adds a coloured glow of
  /// the element's own colour (primary buttons). [k] 0–1 scales everything (materialize, press).
  static List<BoxShadow> of(int level, {required bool dark, Offset tilt = Offset.zero, Color? tint, double k = 1}) {
    final a = -3 * math.pi / 4 + (tilt.dx - tilt.dy) * 35 * math.pi / 180;
    // shadow falls away from the light, with a bias downwards so it never points up
    final sx = -math.cos(a) * 0.45, sy = -math.sin(a) * 0.45 + 0.75;
    final g = dark ? 1.9 : 1.0; // dark ground needs deeper shadows to show at all
    double al(double v) => (v * g * k).clamp(0.0, 1.0);
    final lv = level.clamp(1, 3);
    Color black(double v) => Colors.black.withValues(alpha: al(v));
    return [
      BoxShadow(color: black(0.20), blurRadius: 1.5 * lv, offset: Offset(sx, sy) * (1.0 * lv)),
      BoxShadow(color: black(0.15), blurRadius: 7.0 * lv, offset: Offset(sx, sy) * (3.5 * lv)),
      if (lv >= 2) BoxShadow(color: black(0.11), blurRadius: 20.0 * lv, offset: Offset(sx, sy) * (9.0 * lv)),
      if (lv >= 3) BoxShadow(color: black(0.08), blurRadius: 48, offset: Offset(sx, sy) * 26),
      if (tint != null) BoxShadow(color: tint.withValues(alpha: (dark ? 0.45 : 0.38) * k), blurRadius: 16.0 * lv, spreadRadius: -2, offset: Offset(sx, sy) * (7.0 * lv)),
    ];
  }
}

/// Wraps [child] in layered shadows. Does not clip the child. Off when effects are off (Akku maximal) – then a plain
/// hairline remains, so the element still has an edge.
class FasanDepth extends StatefulWidget {
  const FasanDepth({super.key, required this.child, this.radius, this.level = 2, this.tint, this.pressed = false});

  final Widget child;
  final double? radius;
  final int level;
  final Color? tint;

  /// While pressed the element sinks: shadow shrinks (like a physical button).
  final bool pressed;

  @override
  State<FasanDepth> createState() => _FasanDepthState();
}

class _FasanDepthState extends State<FasanDepth> {
  bool _held = false;

  void _hold(bool want) {
    if (want == _held) return;
    _held = want;
    want ? FasanTilt.instance.acquire() : FasanTilt.instance.release();
  }

  @override
  void dispose() {
    _hold(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = FasanEffectState.of(context);
    final l = st.look;
    final r = BorderRadius.circular(widget.radius ?? l.radius);
    final dark = l.brightness == Brightness.dark;
    final k = widget.pressed ? 0.45 : 1.0;
    // Shadows are always on (Nutzer 03.11.): the effect switch and low battery only decide the tilt, not the shadow.
    // Effects off keep the hairline as well.
    if (!st.on || !st.tilt) {
      _hold(false);
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          border: st.on ? null : Border.all(color: l.hairline),
          boxShadow: FasanShadows.of(widget.level, dark: dark, tint: widget.tint, k: k),
        ),
        child: widget.child,
      );
    }
    _hold(true);
    return AnimatedBuilder(
      animation: FasanTilt.instance,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, boxShadow: FasanShadows.of(widget.level, dark: dark, tilt: FasanTilt.instance.value, tint: widget.tint, k: k)),
        child: child,
      ),
    );
  }
}
