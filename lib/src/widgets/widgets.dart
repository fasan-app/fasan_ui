// fasan_ui – building blocks: glass, pressable, button, segments, person avatars, progress, overlays. MPL-2.0
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../scope.dart';
import '../settings.dart';
import '../theme.dart';
import '../tokens.dart';
import '../tilt.dart';
import '../effects/backdrop.dart';
import '../effects/glass_shader.dart';
import 'depth.dart';

/// Glass panel for the control layer (bars, sheets). Never for content (Apple HIG Liquid Glass: separate layer).
///
/// Made visible by light, not by lines (WWDC25 Session 219, docs/recherche/2026-11-02-glas-neigung-bewegung.md):
/// a light edge with two opposite highlights whose angle follows the device tilt, a tight and a wide shadow, a tint,
/// and it materializes (light and blur rise) instead of fading in. Opaque with a hairline for Braun, while saving power,
/// with „Transparenz reduzieren“ and with high contrast (MediaQuery.highContrast).
class FasanGlass extends StatefulWidget {
  const FasanGlass({super.key, required this.child, this.padding, this.radius, this.highlight = 0, this.tint});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  /// 0–1: extra light (e.g. while pressed).
  final double highlight;

  /// Tinted glass for the main element only (Session 219: tint for primary elements, not for everything).
  final Color? tint;

  @override
  State<FasanGlass> createState() => _FasanGlassState();
}

class _FasanGlassState extends State<FasanGlass> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: FasanDurations.long);
  bool _tiltHeld = false;
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    FasanGlassShader.tier.addListener(_tierChanged);
    if (FasanGlassShader.usable) _shader = FasanGlassShader.program!.fragmentShader();
  }

  void _tierChanged() {
    final want = FasanGlassShader.usable;
    if (want && _shader == null) {
      setState(() => _shader = FasanGlassShader.program!.fragmentShader());
    } else if (!want && _shader != null) {
      _shader!.dispose();
      setState(() => _shader = null);
    }
  }

  /// Stage S0: the rim bends the (already blurred) background; light direction follows the tilt. Materializes by
  /// raising thickness and light with k (Session 219: „modulating the light bending and lensing“).
  Widget _refraction(BorderRadius r, Offset tilt, double k, Widget child) {
    final s = _shader;
    if (s == null) return child;
    final a = -3 * math.pi / 4 + (tilt.dx - tilt.dy) * 35 * math.pi / 180;
    FasanGlassShader.configure(s,
        radius: r.topLeft.x, bevel: 16, thickness: 12 * k + 4 * widget.highlight, light: Offset(math.cos(a), math.sin(a)), spec: 0.9 * k);
    return BackdropFilter(filter: ui.ImageFilter.shader(s), child: child);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_in.value == 0 && !_in.isAnimating) {
      FasanMotion.of(context).enabled ? _in.forward() : _in.value = 1;
    }
  }

  void _holdTilt(bool want) {
    if (want == _tiltHeld) return;
    _tiltHeld = want;
    want ? FasanTilt.instance.acquire() : FasanTilt.instance.release();
  }

  @override
  void dispose() {
    FasanGlassShader.tier.removeListener(_tierChanged);
    _shader?.dispose();
    _holdTilt(false);
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = FasanEffectState.of(context);
    final l = st.look;
    final r = BorderRadius.circular(widget.radius ?? l.radius);
    final dark = l.brightness == Brightness.dark;
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final opaque = l.glassBlur <= 0 || contrast;
    _holdTilt(!opaque && st.tilt);
    final padded = Padding(padding: widget.padding ?? const EdgeInsets.all(FasanSpace.m), child: widget.child);
    if (opaque) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: widget.tint ?? (contrast ? l.surface : l.glassTint),
          borderRadius: r,
          border: Border.all(color: contrast ? l.text : l.hairline, width: contrast ? 1.5 : 0.8),
        ),
        child: padded,
      );
    }
    final tint = widget.tint;
    return AnimatedBuilder(
      animation: Listenable.merge([_in, if (st.tilt) FasanTilt.instance]),
      builder: (context, child) {
        final k = Curves.easeOutCubic.transform(_in.value);
        final tilt = st.tilt ? FasanTilt.instance.value : Offset.zero;
        return DecoratedBox(
          // Two shadows: tight contact and wide lift; deeper in the dark (Session 219: shadow adapts to the ground).
          decoration: BoxDecoration(borderRadius: r, boxShadow: st.shadows ? FasanShadows.of(3, dark: dark, tilt: tilt, k: k) : const []),
          child: ClipRRect(
            borderRadius: r,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: l.glassBlur * k, sigmaY: l.glassBlur * k),
              child: _refraction(
                r,
                tilt,
                k,
                CustomPaint(
                  foregroundPainter: FasanLightEdgePainter(r, tilt, (dark ? 0.62 : 0.95) * k + 0.3 * widget.highlight, dark),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // thinner tint over refracting glass, so the bent background shows through
                      color: tint != null
                          ? tint.withValues(alpha: 0.88)
                          : l.glassTint.withValues(alpha: l.glassTint.a * (0.6 + 0.4 * k) * (_shader != null ? 0.7 : 1)),
                      borderRadius: r,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: padded,
    );
  }
}

/// Light edge of glass: a 1.2 dp rim, bright at the light side and faintly at the opposite side (light passing through).
/// Resting light comes from the top left; tilt turns it by up to ±35°.
class FasanLightEdgePainter extends CustomPainter {
  FasanLightEdgePainter(this.radius, this.tilt, this.strength, this.dark);

  final BorderRadius radius;
  final Offset tilt;
  final double strength;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final rect = Offset.zero & size;
    final rr = radius.toRRect(rect).deflate(0.6);
    final angle = -3 * math.pi / 4 + (tilt.dx - tilt.dy) * 35 * math.pi / 180;
    Color w(double a) => Colors.white.withValues(alpha: (a * strength).clamp(0.0, 1.0));
    final sweep = SweepGradient(
      center: Alignment.center,
      transform: GradientRotation(angle),
      colors: [w(1), w(0.08), w(0.22), w(0.08), w(1)],
      stops: const [0, 0.22, 0.5, 0.78, 1],
    );
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = sweep.createShader(rect));
    // Inner glow: light that has travelled through the glass edge and lights it from within (gives thickness).
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRRect(rr.deflate(1), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..shader = sweep.createShader(rect)
      ..color = Colors.white);
    canvas.restore();
    // Inner sheen: the top part of the glass catches a little more light.
    final sheen = LinearGradient(
      begin: Alignment(math.cos(angle), math.sin(angle)),
      end: Alignment(-math.cos(angle), -math.sin(angle)),
      colors: [w(dark ? 0.26 : 0.45), w(0)],
      stops: const [0, 0.65],
    );
    canvas.drawRRect(rr, Paint()..shader = sheen.createShader(rect));
    // Glare: a soft white patch where the light meets the glass (top left at rest, turns with the tilt) and a faint caustic
    // along the opposite edge (Nutzer 02.11.: „Glas ist kein Glas“; the shader stage reads the background, this part works
    // on every device).
    canvas.save();
    canvas.clipRRect(rr);
    final lx = math.cos(angle), ly = math.sin(angle);
    final glareC = Offset(rect.center.dx + lx * rect.width * 0.34, rect.center.dy + ly * rect.height * 0.34);
    final glareR = math.max(rect.width, rect.height) * 0.6;
    canvas.drawCircle(glareC, glareR, Paint()..shader = RadialGradient(colors: [w(dark ? 0.30 : 0.55), w(0)]).createShader(Rect.fromCircle(center: glareC, radius: glareR)));
    final causticC = Offset(rect.center.dx - lx * rect.width * 0.5, rect.center.dy - ly * rect.height * 0.5);
    final causticR = math.max(rect.width, rect.height) * 0.45;
    canvas.drawCircle(causticC, causticR, Paint()..shader = RadialGradient(colors: [w(dark ? 0.12 : 0.22), w(0)]).createShader(Rect.fromCircle(center: causticC, radius: causticR)));
    canvas.restore();
    // inner edge: a thin darker line just inside the bright rim gives the glass thickness
    canvas.drawRRect(rr.deflate(1.4), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.black.withValues(alpha: (dark ? 0.22 : 0.07) * strength.clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(FasanLightEdgePainter old) => old.tilt != tilt || old.strength != strength || old.radius != radius || old.dark != dark;
}

/// Scales down slightly while pressed and springs back (velocity-free spring, FasanMotion.spring).
/// Gives haptic feedback on tap. The hit area is at least FasanLook.minTap.
class FasanPressable extends StatefulWidget {
  const FasanPressable({super.key, required this.child, this.onTap, this.onLongPress, this.semanticLabel, this.scale = 0.96, this.lightRadius});

  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final String? semanticLabel;
  final double scale;

  /// When set, the surface lights up under the finger (Session 219: light spreads from the fingertip), clipped to this
  /// corner radius.
  final double? lightRadius;

  @override
  State<FasanPressable> createState() => _FasanPressableState();
}

class _FasanPressableState extends State<FasanPressable> with TickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);
  late final AnimationController _light = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), reverseDuration: const Duration(milliseconds: 420));
  Offset _at = Offset.zero;

  void _down(TapDownDetails d) {
    _to(widget.scale);
    if (widget.lightRadius != null && FasanMotion.of(context).enabled) {
      _at = d.localPosition;
      _light.forward();
    }
  }

  void _up() {
    _to(1);
    _light.reverse();
  }

  void _to(double target) {
    final m = FasanMotion.of(context);
    if (!m.enabled) {
      _c.value = target;
      return;
    }
    _c.animateWith(SpringSimulation(m.spring, _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final enabled = widget.onTap != null || widget.onLongPress != null;
    Widget inner = Center(widthFactor: 1, heightFactor: 1, child: widget.child);
    final lr = widget.lightRadius;
    if (lr != null) {
      inner = CustomPaint(
        foregroundPainter: _TouchLightPainter(_light, () => _at, lr, l.brightness == Brightness.dark),
        child: inner,
      );
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? _down : null,
        onTapCancel: enabled ? _up : null,
        onTapUp: enabled ? (_) => _up() : null,
        onTap: widget.onTap == null
            ? null
            : () {
                FasanHaptics.of(context).tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: l.minTap, minHeight: l.minTap),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.scale(scale: _c.value, child: child),
            child: inner,
          ),
        ),
      ),
    );
  }
}

class _TouchLightPainter extends CustomPainter {
  _TouchLightPainter(this.t, this.at, this.radius, this.dark) : super(repaint: t);

  final Animation<double> t;
  final Offset Function() at;
  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v <= 0) return;
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(math.min(radius, size.shortestSide / 2))));
    final c = at();
    const r = 90.0;
    canvas.drawCircle(c, r, Paint()
      ..shader = ui.Gradient.radial(c, r, [Colors.white.withValues(alpha: (dark ? 0.14 : 0.22) * v), Colors.white.withValues(alpha: 0)]));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TouchLightPainter old) => old.radius != radius || old.dark != dark;
}

enum FasanButtonKind { primary, secondary, quiet }

class FasanButton extends StatelessWidget {
  const FasanButton({super.key, required this.label, this.onPressed, this.icon, this.kind = FasanButtonKind.primary, this.expand = false, this.glow});

  /// Glow around the button; default on for primary. At most one per screen (attention rules).
  final bool? glow;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FasanButtonKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final t = Theme.of(context).textTheme.labelLarge!;
    final disabled = onPressed == null;
    final (Color bg, Color fg, Color? border) = switch (kind) {
      FasanButtonKind.primary => (l.accent, l.onAccent, null),
      FasanButtonKind.secondary => (l.surfaceAlt, l.text, null),
      FasanButtonKind.quiet => (Colors.transparent, l.accent, l.hairline),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: FasanSpace.s)],
        Flexible(child: Text(label, style: t.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
      ],
    );
    final radius = l.buttonRadius;
    final lit = l.style.glass && kind != FasanButtonKind.quiet && !disabled;
    Widget body = Container(
      constraints: BoxConstraints(minHeight: l.minTap, minWidth: expand ? double.infinity : 0),
      padding: const EdgeInsets.symmetric(horizontal: FasanSpace.xl, vertical: FasanSpace.m),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border),
      ),
      child: content,
    );
    if (lit) {
      body = CustomPaint(
        foregroundPainter: FasanLightEdgePainter(BorderRadius.circular(radius), Offset.zero, kind == FasanButtonKind.primary ? 0.45 : 0.3, l.brightness == Brightness.dark),
        child: body,
      );
    }
    if ((glow ?? kind == FasanButtonKind.primary) && !disabled && l.glowScale > 0) {
      body = FasanGlow(radius: radius, strength: 0.8 * l.glowScale, child: body);
    }
    if (!disabled && kind != FasanButtonKind.quiet) {
      body = FasanDepth(radius: radius, level: kind == FasanButtonKind.primary ? 2 : 1, tint: kind == FasanButtonKind.primary ? l.accent : null, child: body);
    }
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: FasanPressable(onTap: onPressed, semanticLabel: label, lightRadius: lit ? radius : null, child: body),
    );
  }
}

/// Segmented control with a sliding indicator (Bewegung erklärt Veränderung).
class FasanSegmented<T> extends StatelessWidget {
  const FasanSegmented({super.key, required this.values, required this.selected, required this.label, required this.onChanged});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final idx = math.max(0, values.indexOf(selected));
    final t = Theme.of(context).textTheme.labelMedium!;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth / values.length;
      return Container(
        height: l.minTap,
        decoration: BoxDecoration(color: l.surfaceAlt, borderRadius: BorderRadius.circular(l.radius * 0.7)),
        child: Stack(children: [
          AnimatedPositioned(
            duration: m.medium,
            curve: FasanCurves.medium,
            left: idx * w + 3,
            top: 3,
            bottom: 3,
            width: w - 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: l.surface,
                borderRadius: BorderRadius.circular(l.radius * 0.6),
                border: Border.all(color: l.hairline),
              ),
            ),
          ),
          Row(children: [
            for (final v in values)
              Expanded(
                child: Semantics(
                  selected: v == selected,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(l.radius * 0.6),
                    onTap: () {
                      FasanHaptics.of(context).tap();
                      onChanged(v);
                    },
                    child: Center(
                      child: Text(label(v),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.copyWith(color: v == selected ? l.text : l.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
    });
  }
}

/// Person colours: distinct hues, readable initials (white on these in light, dark text in dark mode).
abstract final class FasanPeople {
  static const _light = [
    Color(0xFF2B54D6), Color(0xFFC2410C), Color(0xFF26745C), Color(0xFF8B3FB8),
    Color(0xFFB4235A), Color(0xFF5B6B12), Color(0xFF00708A), Color(0xFF7A5512),
  ];
  static const _dark = [
    Color(0xFF8AA4FF), Color(0xFFFF8A4C), Color(0xFF5CCFA5), Color(0xFFCB9BF0),
    Color(0xFFFF8FB4), Color(0xFFC3D46A), Color(0xFF6FD3EA), Color(0xFFE6B866),
  ];

  static Color color(int i, Brightness b) => (b == Brightness.dark ? _dark : _light)[i % _light.length];
  static Color on(Brightness b) => b == Brightness.dark ? const Color(0xFF0B0B0C) : Colors.white;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class FasanAvatar extends StatelessWidget {
  const FasanAvatar({super.key, required this.name, required this.index, this.size = 32, this.ring = false});

  final String name;
  final int index;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final c = FasanPeople.color(index, l.brightness);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: ring ? l.text : l.surface, width: ring ? 2 : 1.5),
      ),
      child: Text(
        FasanPeople.initials(name),
        style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: FasanPeople.on(l.brightness), height: 1),
      ),
    );
  }
}

/// Overlapping avatars for shared items (Plan: Avatare statt Farbstreifen).
class FasanAvatarStack extends StatelessWidget {
  const FasanAvatarStack({super.key, required this.people, this.size = 26, this.max = 4});

  /// (name, colour index) pairs.
  final List<(String, int)> people;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final more = people.length - shown.length;
    final step = size * 0.62;
    final n = shown.length + (more > 0 ? 1 : 0);
    return SizedBox(
      width: n == 0 ? 0 : size + step * (n - 1),
      height: size,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(left: i * step, child: FasanAvatar(name: shown[i].$1, index: shown[i].$2, size: size)),
        if (more > 0)
          Positioned(
            left: shown.length * step,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: FasanLook.of(context).surfaceAlt, shape: BoxShape.circle),
              child: Text('+$more', style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

/// Selectable person chip: avatar + name; selected = filled with the person's colour.
class FasanPersonChip extends StatelessWidget {
  const FasanPersonChip({super.key, required this.name, required this.index, required this.selected, this.onTap, this.onLongPress});

  final String name;
  final int index;
  final bool selected;
  final VoidCallback? onTap;

  /// Long press: context menu of the app (rename, only this person …).
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final c = FasanPeople.color(index, l.brightness);
    return Semantics(
      selected: selected,
      child: FasanPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        semanticLabel: name,
        child: AnimatedContainer(
          duration: m.short,
          curve: FasanCurves.short,
          constraints: BoxConstraints(minHeight: l.minTap),
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: selected ? c : l.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c : l.hairline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FasanAvatar(name: name, index: index, size: 34),
            const SizedBox(width: 8),
            Text(name,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: selected ? FasanPeople.on(l.brightness) : l.text)),
          ]),
        ),
      ),
    );
  }
}

/// Progress bar with grooves running backwards: feels faster (Harrison, Yeo & Hudson 2010, GRUNDSAETZE.md).
/// Without motion the grooves stand still.
class FasanProgress extends StatefulWidget {
  const FasanProgress({super.key, required this.value, this.height = 6});

  /// 0–1, or null for indeterminate.
  final double? value;
  final double height;

  @override
  State<FasanProgress> createState() => _FasanProgressState();
}

class _FasanProgressState extends State<FasanProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final run = m.enabled && l.level == FasanPowerLevel.full;
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
    return Semantics(
      value: widget.value == null ? null : '${(widget.value! * 100).round()} %',
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _GroovePainter(widget.value, run ? _c.value : 0, l.accent, l.surfaceAlt),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GroovePainter extends CustomPainter {
  _GroovePainter(this.value, this.phase, this.color, this.track);

  final double? value;
  final double phase;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(r, Paint()..color = track);
    final v = value ?? 1;
    final fill = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width * v.clamp(0, 1), size.height), Radius.circular(size.height / 2));
    canvas.save();
    canvas.clipRRect(fill);
    canvas.drawRRect(fill, Paint()..color = color);
    // Grooves: diagonal light stripes moving right-to-left (against the direction of progress).
    final p = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final gap = size.height * 3;
    for (double x = -gap * 2 - phase * gap; x < size.width + gap; x += gap) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height * 2, 0)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroovePainter o) => o.value != value || o.phase != phase || o.color != color;
}

/// Corner brackets around a region (machine overlay). Thin, precise lines; no decoration beyond that.
class FasanBrackets extends StatelessWidget {
  const FasanBrackets({super.key, required this.child, this.label, this.color, this.inset = 0});

  final Widget child;
  final String? label;
  final Color? color;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final c = color ?? l.line;
    return CustomPaint(
      foregroundPainter: _BracketPainter(c, inset),
      child: Stack(clipBehavior: Clip.none, children: [
        child,
        if (label != null)
          Positioned(
            left: inset + 2,
            top: -16,
            child: Text(label!, style: l.mono(10, color: c, weight: FontWeight.w500)),
          ),
      ]),
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter(this.color, this.inset);

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final k = math.min(16.0, math.min(s.width, s.height) * 0.25);
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    for (final (o, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(o, o + Offset(k * dx, 0), p);
      canvas.drawLine(o, o + Offset(0, k * dy), p);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter o) => o.color != color || o.inset != inset;
}

/// Analysis sweep: a thin line moving down over a region while work is running (machine / sci-fi styles).
/// Stands still without motion or while saving power.
class FasanSweep extends StatefulWidget {
  const FasanSweep({super.key, required this.active});

  final bool active;

  @override
  State<FasanSweep> createState() => _FasanSweepState();
}

class _FasanSweepState extends State<FasanSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final run = widget.active && FasanMotion.of(context).enabled && l.level == FasanPowerLevel.full;
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _SweepPainter(run ? _c.value : 0.5, l.line), size: Size.infinite),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height * Curves.easeInOut.transform(t);
    final rect = Rect.fromLTWH(0, y - 24, s.width, 24);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.22)],
        ).createShader(rect),
    );
    canvas.drawLine(Offset(0, y), Offset(s.width, y), Paint()..color = color..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_SweepPainter o) => o.t != t || o.color != color;
}

/// Small caps label for sections; monospace in cinematic styles.
class FasanLabel extends StatelessWidget {
  const FasanLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    // same box in every style (norm against jumping): one line, fixed height; only the family changes
    final base = Theme.of(context).textTheme.labelMedium!;
    final style = l.style.cinematic ? base.copyWith(fontFamily: l.monoFamily, package: l.fontPackage) : base;
    return SizedBox(height: 18, child: Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis));
  }
}


/// Shows or hides [child] with a smooth size change and fade (Nutzer 02.11.: wenn eine Änderung im Menü weitere Unterpunkte
/// einblendet, dürfen die Zeilen darunter nicht springen). Same idea as Apple's guidance to animate state-driven layout
/// changes (SwiftUI `withAnimation`, HIG „Motion“): the size animates, the content fades, both with the style's curve.
/// Without motion it switches at once.
class FasanReveal extends StatelessWidget {
  const FasanReveal({super.key, required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = FasanMotion.of(context);
    // Without motion no AnimatedSize: with a zero duration it finishes inside its own layout (Flutter asserts).
    if (!m.enabled) return show ? child : const SizedBox(width: double.infinity);
    return AnimatedSize(
      duration: m.medium,
      curve: FasanCurves.medium,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: m.medium,
        switchInCurve: FasanCurves.medium,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        // old and new child stack at the top, so the size follows the newest one while the old fades out
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: show ? KeyedSubtree(key: const ValueKey('shown'), child: child) : const SizedBox(key: ValueKey('hidden'), width: double.infinity),
      ),
    );
  }
}

/// A switch row that gives feedback: haptic tick and click when it is toggled (Nutzer 02.11.: Schalter im Menü blieben
/// still). Material's [SwitchListTile] has none of its own.
class FasanSwitchTile extends StatelessWidget {
  const FasanSwitchTile({super.key, required this.title, required this.value, required this.onChanged, this.subtitle, this.secondary, this.padded = false});

  final Widget title;
  final Widget? secondary;

  /// Default list padding (true) or none (false, used inside cards and padded pages).
  final bool padded;
  final Widget? subtitle;
  final bool value;

  /// Null disables the row.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: padded ? null : EdgeInsets.zero,
      secondary: secondary,
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              FasanHaptics.of(context).tap();
              onChanged!(v);
            },
    );
  }
}
