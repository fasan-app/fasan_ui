// fasan_ui – refracting glass (stage S0 of docs/recherche/2026-11-02-echtes-glas-flutter.md §6) with a start-up probe.
// MPL-2.0
//
// Reading the background (BackdropFilter + ImageFilter.shader) broke before: upside down on the emulator (GLES),
// a dark box on the S23 (grain overflow, see film.dart). So the device decides, not a model list (Fasan rule
// „Verhalten aus Fähigkeiten“): FasanGlassProbe renders a 32×32 test – red on top, blue below – through the glass
// shader, reads the pixels back and allows refraction only if the picture is upright and not black. Otherwise glass
// stays at stage S2 (blur + light edge, no background-reading shader). The result is shown on the effect test page.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum FasanGlassTier {
  /// Probe not finished yet: behave like [blur].
  unknown,

  /// Refraction, specular rim and Fresnel through the shader (S0).
  refract,

  /// Blur + tint + light edge, no background-reading shader (S2).
  blur,
}

abstract final class FasanGlassShader {
  static ui.FragmentProgram? program;
  static Future<void>? _loading;
  static final tier = ValueNotifier<FasanGlassTier>(FasanGlassTier.unknown);

  /// Why the probe failed (effect test page), or null.
  static String? reason;

  /// Probe pixels as text („oben rgb, unten rgb, Rückgabe“) for the log: tells what the device really does.
  static String? probePixels;

  /// True when the probe saw the picture upside down: refraction is still used, the shader flips the lookup.
  static bool flipY = false;

  static Future<void> ensureLoaded() => _loading ??= () async {
        try {
          program = await ui.FragmentProgram.fromAsset('packages/fasan_ui/shaders/glass.frag');
        } catch (e) {
          program = null;
          reason = 'Shader nicht geladen: $e';
        }
      }();

  /// Off since 03.11.: on the S23 ImageFilter.shader paints the glass black, so no screen uses it. Glass stays at the
  /// blur stage (S2) until the background is read another way (RepaintBoundary.toImageSync, docs/STAND in Split).
  static const bool refractionEnabled = false;

  static bool get usable => refractionEnabled && tier.value == FasanGlassTier.refract && program != null && ui.ImageFilter.isShaderFilterSupported;

  /// Sets the floats of glass.frag. Index 0/1 (uSize) and the sampler are set by the engine; ours start at 2
  /// (docs/recherche/2026-11-02-echtes-glas-flutter.md §1, SDK painting.dart ImageFilter.shader).
  static void configure(ui.FragmentShader s,
      {required double radius, double bevel = 14, double thickness = 10, double ior = 1.5, Offset light = const Offset(-0.7071, -0.7071), double spec = 0.9, Color tint = Colors.white, double tintAlpha = 0.0}) {
    s
      ..setFloat(2, radius)
      ..setFloat(3, bevel)
      ..setFloat(4, thickness)
      ..setFloat(5, ior)
      ..setFloat(6, light.dx)
      ..setFloat(7, light.dy)
      ..setFloat(8, spec)
      ..setFloat(9, tintAlpha)
      ..setFloat(10, tint.r)
      ..setFloat(11, tint.g)
      ..setFloat(12, tint.b)
      ..setFloat(13, flipY ? 1 : 0);
  }
}

/// Invisible 32×32 probe, placed outside the screen by FasanBackdrop. Runs once per app start.
class FasanGlassProbe extends StatefulWidget {
  const FasanGlassProbe({super.key});

  @override
  State<FasanGlassProbe> createState() => _FasanGlassProbeState();
}

class _FasanGlassProbeState extends State<FasanGlassProbe> {
  final _key = GlobalKey();
  ui.FragmentShader? _shader;
  static bool _done = false;

  @override
  void initState() {
    super.initState();
    if (_done) return;
    if (!FasanGlassShader.refractionEnabled) {
      FasanGlassShader.reason = 'Brechung aus (ImageFilter.shader schwarz auf dem S23)';
      FasanGlassShader.tier.value = FasanGlassTier.blur;
      _done = true;
      return;
    }
    if (!ui.ImageFilter.isShaderFilterSupported) {
      FasanGlassShader.reason = 'ImageFilter.shader nicht unterstützt (kein Impeller)';
      FasanGlassShader.tier.value = FasanGlassTier.blur;
      _done = true;
      return;
    }
    FasanGlassShader.ensureLoaded().then((_) {
      final p = FasanGlassShader.program;
      if (!mounted) return;
      if (p == null) {
        FasanGlassShader.tier.value = FasanGlassTier.blur;
        _done = true;
        return;
      }
      setState(() => _shader = p.fragmentShader());
      // two frames: one to paint, one so the backdrop is filled
      WidgetsBinding.instance.addPostFrameCallback((_) => WidgetsBinding.instance.addPostFrameCallback((_) => _check()));
    });
  }

  Future<void> _check() async {
    if (_done) return;
    _done = true;
    try {
      final b = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (b == null) throw StateError('keine Zeichenfläche');
      final img = await b.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      if (data == null) throw StateError('keine Pixel');
      final (top, bottom) = _sample(data, img.width, img.height);
      FasanGlassShader.probePixels = 'oben rgb${top.$1},${top.$2},${top.$3} unten rgb${bottom.$1},${bottom.$2},${bottom.$3}';
      bool isRed((int, int, int) c) => c.$1 > 140 && c.$1 > c.$3 + 60;
      bool isBlue((int, int, int) c) => c.$3 > 140 && c.$3 > c.$1 + 60;
      if (isRed(top) && isBlue(bottom)) {
        FasanGlassShader.flipY = false;
        FasanGlassShader.reason = null;
        FasanGlassShader.tier.value = FasanGlassTier.refract;
      } else if (isBlue(top) && isRed(bottom)) {
        // upside down but otherwise fine: the shader flips the lookup (uFlip), no need to give up refraction
        FasanGlassShader.flipY = true;
        FasanGlassShader.reason = 'Hintergrund kopfüber, wird im Shader gedreht';
        FasanGlassShader.tier.value = FasanGlassTier.refract;
      } else {
        FasanGlassShader.reason = 'Testbild falsch (${FasanGlassShader.probePixels})';
        FasanGlassShader.tier.value = FasanGlassTier.blur;
      }
    } catch (e) {
      FasanGlassShader.reason = 'Selbsttest: $e';
      FasanGlassShader.tier.value = FasanGlassTier.blur;
    }
    if (mounted) setState(() {});
  }

  /// Colours at top centre and bottom centre of the probe picture.
  static ((int, int, int), (int, int, int)) _sample(ByteData d, int w, int h) {
    (int, int, int) px(int x, int y) {
      final i = (y * w + x) * 4;
      return (d.getUint8(i), d.getUint8(i + 1), d.getUint8(i + 2));
    }

    return (px(w ~/ 2, h ~/ 6), px(w ~/ 2, h - 1 - h ~/ 6));
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _shader;
    if (s == null || _done && FasanGlassShader.tier.value != FasanGlassTier.unknown) return const SizedBox(width: 32, height: 32);
    FasanGlassShader.configure(s, radius: 0, bevel: 1, thickness: 0, spec: 0);
    return RepaintBoundary(
      key: _key,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(children: [
          const Column(children: [
            Expanded(child: ColoredBox(color: Color(0xFFFF0000))),
            Expanded(child: ColoredBox(color: Color(0xFF0000FF))),
          ]),
          Positioned.fill(child: ClipRect(child: BackdropFilter(filter: ui.ImageFilter.shader(s), child: const SizedBox.expand()))),
        ]),
      ),
    );
  }
}
