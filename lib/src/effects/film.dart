// fasan_ui – film effects: grain, gate weave (Bildstandwackeln), glow, halation, light bleeding. MPL-2.0
//
// API facts (docs.flutter.dev/ui/design/graphics/fragment-shaders and dart:ui in Flutter 3.47.7):
// - FragmentProgram.fromAsset('packages/fasan_ui/shaders/…') for shaders shipped in a package.
// - ImageFilter.shader works only with Impeller; ImageFilter.isShaderFilterSupported tells whether it is available.
// Power rules (Beschluss 01.11.): full → all chosen effects; save → only still grain; maximum → nothing.
// Motion off ("Animationen entfernen" or "Weniger Bewegung") → still grain, no weave.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../scope.dart';
import '../settings.dart';
import '../theme.dart';

class _Programs {
  static Future<(ui.FragmentProgram?, ui.FragmentProgram?)>? _loading;

  static Future<(ui.FragmentProgram?, ui.FragmentProgram?)> load() => _loading ??= () async {
        Future<ui.FragmentProgram?> one(String name) async {
          try {
            return await ui.FragmentProgram.fromAsset('packages/fasan_ui/shaders/$name.frag');
          } catch (_) {
            return null; // e.g. tests without shader support: effects are optional
          }
        }

        return (await one('grain'), await one('bloom'));
      }();
}

/// Wraps a screen (or a picture) with the film effects of the current settings.
class FasanFilm extends StatefulWidget {
  const FasanFilm({super.key, required this.child, this.effects});

  /// Glow, halation and light bleeding (ImageFilter.shader). False until the shader renders correctly on Impeller
  /// OpenGLES and Vulkan; the settings hide their sliders while false.
  static const bool bloomVerified = false;

  final Widget child;

  /// Overrides the settings (gallery previews); null = from the theme.
  final FilmEffectSettings? effects;

  @override
  State<FasanFilm> createState() => _FasanFilmState();
}

class _FasanFilmState extends State<FasanFilm> with SingleTickerProviderStateMixin {
  ui.FragmentShader? _grain, _bloom;
  late final Ticker _ticker = createTicker(_tick);
  double _time = 0;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _Programs.load().then((p) {
      if (!mounted) return;
      setState(() {
        _grain = p.$1?.fragmentShader();
        _bloom = p.$2?.fragmentShader();
      });
    });
  }

  void _tick(Duration t) {
    // 24 updates per second are enough for film grain and weave and cost less than 60/120 Hz.
    if (t - _last < const Duration(milliseconds: 41)) return;
    _last = t;
    setState(() => _time = t.inMicroseconds / 1e6);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _grain?.dispose();
    _bloom?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final look = FasanLook.of(context);
    final fx = widget.effects ?? look.effects;
    final motion = FasanMotion.of(context);
    final level = look.level;
    final on = fx.enabled && level != FasanPowerLevel.maximum;
    final full = on && level == FasanPowerLevel.full;
    final animate = full && motion.enabled && (fx.grain > 0 || fx.weave > 0);
    if (animate && !_ticker.isActive) {
      _ticker.start();
    } else if (!animate && _ticker.isActive) {
      _ticker.stop();
    }
    if (!on) return widget.child;

    Widget w = RepaintBoundary(child: widget.child);
    final bloom = _bloom;
    // Off until verified on both Impeller backends: on the Android emulator (Impeller OpenGLES) this filter turned the
    // whole app upside down and smeared text; on a Galaxy S23 a dark box appeared (fasan-diagnose, Emulator-Bilder
    // 02.11., Nutzer-Bildschirmfotos 0.1.2). Grain and weave do not sample the screen and stay on.
    if (FasanFilm.bloomVerified && full && bloom != null && ui.ImageFilter.isShaderFilterSupported && (fx.glow + fx.halation + fx.bleed) > 0) {
      bloom
        ..setFloat(2, fx.glow)
        ..setFloat(3, fx.halation)
        ..setFloat(4, fx.bleed)
        ..setFloat(5, 10 * MediaQuery.devicePixelRatioOf(context));
      w = ImageFiltered(imageFilter: ui.ImageFilter.shader(bloom), child: w);
    }
    if (full && motion.enabled && fx.weave > 0) {
      // Gate weave: the frame drifts below one pixel, slowly and irregularly (two sines, no randomness per frame).
      final a = fx.weave * 0.9;
      final dx = a * (math.sin(_time * 2.1) * 0.6 + math.sin(_time * 5.3 + 1.7) * 0.4);
      final dy = a * (math.sin(_time * 1.7 + 0.4) * 0.7 + math.sin(_time * 4.1) * 0.3);
      w = Transform.translate(offset: Offset(dx, dy), child: w);
    }
    final grain = _grain;
    if (grain != null && fx.grain > 0) {
      w = Stack(
        fit: StackFit.passthrough,
        children: [
          w,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _GrainPainter(grain, animate ? _time : 0, fx.grain, look.brightness, MediaQuery.devicePixelRatioOf(context))),
              ),
            ),
          ),
        ],
      );
    }
    return w;
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.shader, this.time, this.amount, this.brightness, this.dpr);

  final ui.FragmentShader shader;
  final double time, amount, dpr;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      // Grain reads stronger on light backgrounds; slightly less there keeps text calm.
      ..setFloat(3, amount * (brightness == Brightness.dark ? 1.0 : 0.7))
      // Grain cell size. FlutterFragCoord gives local coordinates, unlike gl_FragCoord (screen space)
      // (docs.flutter.dev/ui/design/graphics/fragment-shaders); whether these are logical or physical pixels on the
      // device is nicht geprüft – the dpr is passed along so a future fix needs no API change.
      ..setFloat(4, 1.6);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GrainPainter old) => old.time != time || old.amount != amount || old.brightness != brightness || old.dpr != dpr;
}
