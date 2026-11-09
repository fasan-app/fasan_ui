// fasan_ui – the grain template of the AV1 film grain synthesis (spec 7.18.3; Norkin/Birkbeck, DCC 2018). MPL-2.0
//
// An 82×73 field of Gaussian random numbers, filtered by an autoregressive filter of lag 3 (24 causal neighbours):
// every value is a random draw plus a weighted sum of the already made values around it. That makes the grain correlated
// (soft clumps) instead of white „ISO noise“. The shader cuts 32×32 blocks out of it with a random offset per frame.
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Template size of the AV1 luma grain: 82 wide, 73 high.
const int grainTemplateW = 82, grainTemplateH = 73;

/// Unit-variance template values, row by row. [seed] makes it reproducible; [reach] sets how far the correlation reaches
/// (the AR weights fall off as exp(−distance / reach)); the weights stay far below the stability limit (sum < 1).
Float32List grainTemplateValues({int seed = 7, double reach = 1.6}) {
  const lag = 3, w = grainTemplateW, h = grainTemplateH;
  final rnd = math.Random(seed);
  double gauss() {
    final u1 = math.max(1e-9, rnd.nextDouble()), u2 = rnd.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  // causal neighbours: the rows above (dy −3…−1, dx −3…3) and the pixels to the left in this row (dx −3…−1): 24 in all
  final taps = <(int, int, double)>[];
  for (var dy = -lag; dy <= 0; dy++) {
    for (var dx = -lag; dx <= lag; dx++) {
      if (dy == 0 && dx >= 0) break;
      final dist = math.sqrt(dy * dy + dx * dx);
      taps.add((dy, dx, 0.18 * math.exp(-dist / reach)));
    }
  }
  final g = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var v = gauss();
      for (final (dy, dx, a) in taps) {
        final yy = y + dy, xx = x + dx;
        if (yy >= 0 && xx >= 0 && xx < w) v += a * g[yy * w + xx];
      }
      g[y * w + x] = v;
    }
  }
  var mean = 0.0;
  for (final v in g) {
    mean += v;
  }
  mean /= g.length;
  var varSum = 0.0;
  for (final v in g) {
    varSum += (v - mean) * (v - mean);
  }
  final sd = math.sqrt(varSum / g.length);
  for (var i = 0; i < g.length; i++) {
    g[i] = (g[i] - mean) / sd;
  }
  return g;
}

/// The template as a small image for the shader: red channel = 0.5 + value / 6 (values beyond ±3 are cut).
Future<ui.Image> makeGrainTemplate({int seed = 7}) {
  final v = grainTemplateValues(seed: seed);
  final px = Uint8List(v.length * 4);
  for (var i = 0; i < v.length; i++) {
    final b = ((0.5 + v[i] / 6).clamp(0.0, 1.0) * 255).round();
    px[i * 4] = b;
    px[i * 4 + 1] = b;
    px[i * 4 + 2] = b;
    px[i * 4 + 3] = 255;
  }
  final c = Completer<ui.Image>();
  ui.decodeImageFromPixels(px, grainTemplateW, grainTemplateH, ui.PixelFormat.rgba8888, c.complete);
  return c.future;
}
