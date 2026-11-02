// fasan_ui – film grain and gate weave over the whole picture (setting „Ebene: ganzes Bild“). MPL-2.0
//
// Default is the ground only (FasanBackdrop, GESTALTUNG.md §2): grain never lies over text then. This widget wraps the
// app (MaterialApp.builder) and does nothing unless the user picks „ganzes Bild“.
//
// API facts (docs.flutter.dev/ui/design/graphics/fragment-shaders, Flutter 3.47.7):
// - FragmentProgram.fromAsset('packages/fasan_ui/shaders/…') for shaders shipped in a package.
// - The grain shader reads no image (Paint.shader), so it does not depend on ImageFilter.shader. The former screen
//   bloom did and failed on Impeller GLES (emulator: upside down) and on the S23 (dark box); it was removed on 02.11.
// Power rules (Beschluss 01.11.): full → all chosen effects; save → still grain only; maximum → nothing.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../settings.dart';
import 'backdrop.dart';

class FasanFilm extends StatefulWidget {
  const FasanFilm({super.key, required this.child, this.effects});

  final Widget child;

  /// Overrides the settings (gallery previews); null = from the theme.
  final FilmEffectSettings? effects;

  static ui.FragmentProgram? grainProgram;
  static Future<void>? _loading;

  /// Loads the grain shader once. Fails quietly where shaders are unavailable (unit tests): grain is optional.
  static Future<void> ensureLoaded() => _loading ??= () async {
        try {
          grainProgram = await ui.FragmentProgram.fromAsset('packages/fasan_ui/shaders/grain.frag');
        } catch (_) {
          grainProgram = null;
        }
      }();

  /// True below a FasanFilm that already draws grain over the whole picture (avoids a second overlay in previews).
  static bool coversWhole(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_WholeMarker>() != null;

  /// Gate weave: the frame drifts slowly and irregularly (two sines, no randomness per frame). weave 1 → up to 3 px.
  static Offset weaveOffset(double t, double weave) {
    final a = weave * 3;
    return Offset(
      a * (math.sin(t * 2.1) * 0.6 + math.sin(t * 5.3 + 1.7) * 0.4),
      a * (math.sin(t * 1.7 + 0.4) * 0.7 + math.sin(t * 4.1) * 0.3),
    );
  }

  @override
  State<FasanFilm> createState() => _FasanFilmState();
}

class _FasanFilmState extends State<FasanFilm> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _grain;
  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    FasanFilm.ensureLoaded().then((_) {
      if (mounted && FasanFilm.grainProgram != null) setState(() => _grain = FasanFilm.grainProgram!.fragmentShader());
    });
  }

  void _tick(Duration t) {
    if (t - _last < const Duration(milliseconds: 41)) return;
    _last = t;
    _time.value = FasanClock.seconds;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _grain?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = FasanEffectState.of(context, widget.effects);
    final fx = st.fx;
    final whole = st.on && fx.layer == FasanFilmLayer.whole && !FasanFilm.coversWhole(context);
    final animate = whole && st.animate && (fx.grain > 0 || fx.weave > 0);
    if (animate && !_ticker.isActive) _ticker.start();
    if (!animate && _ticker.isActive) _ticker.stop();
    if (!whole) return widget.child;

    Widget w = RepaintBoundary(child: widget.child);
    if (animate && fx.weave > 0) {
      w = ValueListenableBuilder<double>(
        valueListenable: _time,
        builder: (context, t, child) => Transform.translate(offset: FasanFilm.weaveOffset(t, fx.weave), child: child),
        child: w,
      );
    }
    final grain = _grain;
    if (grain != null && fx.grain > 0) {
      w = Stack(fit: StackFit.passthrough, children: [
        w,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: FasanGrainPainter(grain, fx, st.look.brightness, MediaQuery.devicePixelRatioOf(context), animate ? _time : null),
              ),
            ),
          ),
        ),
      ]);
    }
    return _WholeMarker(child: w);
  }
}

class _WholeMarker extends InheritedWidget {
  const _WholeMarker({required super.child});

  @override
  bool updateShouldNotify(_WholeMarker oldWidget) => false;
}

/// Paints grain with shaders/grain.frag. time null = still grain.
class FasanGrainPainter extends CustomPainter {
  FasanGrainPainter(this.shader, this.fx, this.brightness, this.dpr, this.time) : super(repaint: time);

  final ui.FragmentShader shader;
  final FilmEffectSettings fx;
  final Brightness brightness;
  final double dpr;
  final ValueListenable<double>? time;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time?.value ?? 0;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      // grainSpeed scales the frame clock: 1 → 24 grain frames per second, 0 → still.
      ..setFloat(2, t * fx.grainSpeed)
      // Grain reads stronger on light backgrounds.
      ..setFloat(3, fx.grain * (brightness == Brightness.dark ? 1.0 : 0.7))
      // Cell size. FlutterFragCoord is in local canvas units; logical vs physical pixels on the device: nicht geprüft
      // (Effekt-Testseite zeigt die Größe zum Vergleich).
      ..setFloat(4, fx.grainPx);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(FasanGrainPainter old) => old.fx != fx || old.brightness != brightness || old.dpr != dpr || old.time != time;
}
