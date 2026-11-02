// fasan_ui – layer 0 („Grund“) and layer 3 („Rückmeldung“) of GESTALTUNG.md §2. MPL-2.0
//
// Ground: three soft colour spots drifting on a 32 s period, a light spot from the light direction (Überstrahlen),
// a light band that crosses once every 14 s (Lichteinfall), grain and gate weave – all behind the content.
// Glow: soft shine and warm halation around one element, plus a one-time ring pulse (attention rules,
// docs/recherche/2026-11-02-farbe-verlauf-aufmerksamkeit.md §2: one pulse 600 ms, opacity ≤ 0.35, no permanent pulsing).
// Nothing here samples the screen (no ImageFilter.shader): the earlier screen bloom broke on Impeller GLES/S23.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../scope.dart';
import '../settings.dart';
import '../theme.dart';
import '../tilt.dart';
import 'film.dart';

/// One clock for all effects, so the ground continues seamlessly across routes and previews.
abstract final class FasanClock {
  static final Stopwatch _w = Stopwatch()..start();
  static double get seconds => _w.elapsedMicroseconds / 1e6;
}

/// Effective state of the ground effects for this context.
class FasanEffectState {
  FasanEffectState._(this.fx, this.animate, this.on, this.look);

  factory FasanEffectState.of(BuildContext context, [FilmEffectSettings? override]) {
    final look = FasanLook.of(context);
    final fx = override ?? look.effects;
    final on = fx.enabled && look.level != FasanPowerLevel.maximum;
    final animate = on && look.level == FasanPowerLevel.full && FasanMotion.of(context).enabled;
    return FasanEffectState._(fx, animate, on, look);
  }

  final FilmEffectSettings fx;
  final FasanLook look;

  /// Effects drawn at all (off with „Akku maximal“ or the master switch).
  final bool on;

  /// Effects move (full power and motion allowed).
  final bool animate;

  /// Glass light follows the tilt.
  bool get tilt => animate && fx.tilt;
}

/// Ground behind the content. Put it behind the Navigator (MaterialApp.builder) with transparent scaffolds, or locally
/// behind a preview.
class FasanBackdrop extends StatefulWidget {
  const FasanBackdrop({super.key, required this.child, this.effects});

  final Widget child;
  final FilmEffectSettings? effects;

  @override
  State<FasanBackdrop> createState() => _FasanBackdropState();
}

class _FasanBackdropState extends State<FasanBackdrop> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  bool _tiltHeld = false;
  ui.FragmentShader? _grain;

  @override
  void initState() {
    super.initState();
    FasanFilm.ensureLoaded().then((_) {
      if (mounted && FasanFilm.grainProgram != null) setState(() => _grain = FasanFilm.grainProgram!.fragmentShader());
    });
  }

  void _tick(Duration t) {
    // 24 updates per second: enough for grain and weave, and slow drifts look continuous at that rate.
    if (t - _last < const Duration(milliseconds: 41)) return;
    _last = t;
    _time.value = FasanClock.seconds;
  }

  void _holdTilt(bool want) {
    if (want == _tiltHeld) return;
    _tiltHeld = want;
    want ? FasanTilt.instance.acquire() : FasanTilt.instance.release();
  }

  @override
  void dispose() {
    _holdTilt(false);
    _ticker.dispose();
    _grain?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = FasanEffectState.of(context, widget.effects);
    final l = st.look;
    final fx = st.fx;
    final moving = st.animate && (fx.gradient || fx.lightSweep || fx.grain > 0 || fx.weave > 0);
    if (moving && !_ticker.isActive) _ticker.start();
    if (!moving && _ticker.isActive) _ticker.stop();
    if (!moving) _time.value = 0;
    _holdTilt(st.tilt && fx.bleed > 0);
    final grainHere = fx.grain > 0 && (fx.layer == FasanFilmLayer.ground || !FasanFilm.coversWhole(context));
    final grain = _grain;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget ground = CustomPaint(
      painter: _GroundPainter(
        look: l,
        fx: fx,
        on: st.on,
        time: _time,
        tilt: st.tilt ? FasanTilt.instance : null,
      ),
      child: const SizedBox.expand(),
    );
    if (st.on && grainHere && grain != null) {
      ground = Stack(fit: StackFit.expand, children: [
        ground,
        CustomPaint(painter: FasanGrainPainter(grain, fx, l.brightness, dpr, st.animate ? _time : null)),
      ]);
    }
    if (st.on && st.animate && fx.weave > 0 && fx.layer == FasanFilmLayer.ground) {
      // Weave of the ground only. Inflated by 4 px so the moving edge never shows.
      ground = ValueListenableBuilder<double>(
        valueListenable: _time,
        builder: (context, t, child) => Transform.translate(offset: FasanFilm.weaveOffset(t, fx.weave), child: child),
        child: Transform.scale(scale: 1.012, child: ground),
      );
    }
    return Stack(fit: StackFit.passthrough, children: [
      Positioned.fill(child: IgnorePointer(child: ClipRect(child: RepaintBoundary(child: ground)))),
      widget.child,
    ]);
  }
}

class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.look, required this.fx, required this.on, required this.time, this.tilt})
      : super(repaint: Listenable.merge([time, ?tilt]));

  final FasanLook look;
  final FilmEffectSettings fx;
  final bool on;
  final ValueNotifier<double> time;
  final FasanTilt? tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = look.background);
    if (!on) return;
    final t = time.value;
    final w = size.width, h = size.height, d = math.max(w, h);
    final dark = look.brightness == Brightness.dark;

    // Colour spots: each on its own slow ellipse; path ≤ 10 % of the width (GESTALTUNG.md §3).
    if (fx.gradient && look.blobs.isNotEmpty) {
      const anchors = [Offset(0.18, 0.12), Offset(0.88, 0.42), Offset(0.30, 0.92)];
      const radii = [0.75, 0.65, 0.70];
      const period = 32.0;
      for (var i = 0; i < look.blobs.length && i < anchors.length; i++) {
        final p = 2 * math.pi * (t / period + i / 3);
        final c = Offset(
          (anchors[i].dx + 0.10 * math.sin(p)) * w,
          (anchors[i].dy + 0.06 * math.cos(p * 0.8 + i)) * h,
        );
        final r = radii[i] * d;
        canvas.drawCircle(
          c,
          r,
          Paint()..shader = ui.Gradient.radial(c, r, [look.blobs[i], look.blobs[i].withValues(alpha: 0)], const [0, 1]),
        );
      }
    }

    // Überstrahlen: light spot from the light direction (top left), shifts against the tilt (parallax).
    if (fx.bleed > 0) {
      final v = tilt?.value ?? Offset.zero;
      final c = Offset(w * (0.08 - 0.10 * v.dx), h * (0.02 - 0.06 * v.dy));
      final r = d * 0.55;
      final warm = dark ? const Color(0xFFFFE2C2) : const Color(0xFFFFF4E4);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..blendMode = dark ? BlendMode.plus : BlendMode.srcOver
          ..shader = ui.Gradient.radial(c, r, [warm.withValues(alpha: fx.bleed * (dark ? 0.16 : 0.55)), warm.withValues(alpha: 0)], const [0, 1]),
      );
    }

    // Lichteinfall: a soft diagonal band crosses in 2.4 s once every 14 s.
    if (fx.lightSweep && t > 0) {
      const every = 14.0, run = 2.4;
      final phase = (t % every) / run;
      if (phase < 1) {
        final eased = Curves.easeInOutSine.transform(phase);
        final x = -0.4 * w + eased * 1.8 * w;
        final band = w * 0.35;
        final a = (dark ? 0.06 : 0.16) * math.sin(math.pi * phase);
        final shader = ui.Gradient.linear(
          Offset(x - band, -h * 0.1),
          Offset(x + band, h * 0.25),
          [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: a), Colors.white.withValues(alpha: 0)],
          const [0, 0.5, 1],
        );
        canvas.drawRect(rect, Paint()..shader = shader..blendMode = dark ? BlendMode.plus : BlendMode.srcOver);
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.look != look || old.fx != fx || old.on != on || old.tilt != tilt;
}

/// Glow, halation and a one-time ring pulse around one element (layer 3). Use for the main action and the total only:
/// at most one attention area per screen.
class FasanGlow extends StatefulWidget {
  const FasanGlow({super.key, required this.child, this.radius, this.color, this.pulse = 0, this.strength = 1});

  final Widget child;
  final double? radius;

  /// Defaults to the accent.
  final Color? color;

  /// Change the value to play the ring pulse once (e.g. when the total matches).
  final int pulse;

  /// Scales glow and halation (0 = only the pulse).
  final double strength;

  @override
  State<FasanGlow> createState() => _FasanGlowState();
}

class _FasanGlowState extends State<FasanGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(FasanGlow old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse && FasanMotion.of(context).enabled) _ring.forward(from: 0);
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = FasanEffectState.of(context);
    final l = st.look;
    final color = widget.color ?? l.accent;
    final r = widget.radius ?? l.radius;
    final glow = st.on ? st.fx.glow * widget.strength : 0.0;
    final halo = st.on ? st.fx.halation * widget.strength : 0.0;
    return CustomPaint(
      painter: _GlowPainter(color, r, glow, halo, _ring, l.brightness),
      child: widget.child,
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.color, this.radius, this.glow, this.halation, this.ring, this.brightness) : super(repaint: ring);

  final Color color;
  final double radius, glow, halation;
  final Animation<double> ring;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final dark = brightness == Brightness.dark;
    if (glow > 0) {
      // Soft shine of the element's own colour; stronger in the dark, where light reads as light.
      canvas.drawRRect(
        rr.shift(const Offset(0, 6)),
        Paint()
          ..color = color.withValues(alpha: glow * (dark ? 0.55 : 0.38))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
    if (halation > 0) {
      // Halation: warm red fringe where bright light meets film (the red layer sits deepest in colour film).
      canvas.drawRRect(
        rr.inflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFF5A36).withValues(alpha: halation * (dark ? 0.45 : 0.30))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
    final p = ring.value;
    if (p > 0 && p < 1) {
      // One ring: opacity 0 → 0.35 → 0, grows 0 → 12 px (attention rules §2).
      final a = 0.35 * math.sin(math.pi * p);
      canvas.drawRRect(
        rr.inflate(2 + 12 * Curves.easeOutCubic.transform(p)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: a)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + 6 * p),
      );
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.color != color || old.radius != radius || old.glow != glow || old.halation != halation || old.brightness != brightness;
}
