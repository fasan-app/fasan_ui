// fasan_ui – film grain and old-film artefacts as an overlay (Paint.shader, reads no image). MPL-2.0
// 0.1.23: grain after the AV1 film grain synthesis (spec 7.18.3; Norkin/Birkbeck, DCC 2018): a 82×73 template made by an
// autoregressive filter (Dart), 32×32 blocks with a random offset into the template per frame, 2 px overlap between
// blocks, strength by brightness. Correlated, no longer white „ISO noise“ (Nutzer 02.11.).
// Basis: docs/recherche/2026-11-02-filmkorn-alter-film.md (Newson 2017 / AV1: Gaussian grain, new per frame and
// independent per place, strength by brightness; Hoskins „Hash without Sine“, MIT). Flutter shader rules:
// docs.flutter.dev/ui/design/graphics/fragment-shaders (float uniforms only, set in declaration order).
//
// Until 0.1.15 the frame index shifted one hash field (cell + frame·(17,31)): the whole pattern slid diagonally –
// the „gleichmäßig in eine Richtung bewegende Animation“ the user saw. Now every cell draws a new Gaussian value from
// (cell, frame seed): no motion, only flicker of independent grains.
#version 460 core
#include <flutter/runtime_effect.glsl>

// highp: mediump overflowed in the old hash on the Galaxy S23 (fp16), see git history (dunkler Kasten).
precision highp float;

uniform vec2 uSize;      // 0,1  canvas size
uniform float uSeed;     // 2    new for every grain frame (0…61), from Dart
uniform float uSlow;     // 3    changes every ~1 s (scratches), from Dart
uniform float uTime;     // 4    seconds (slow drift of scratches and flicker)
uniform float uGrain;    // 5    0…1 strength (standard deviation of the overlay)
uniform float uCell;     // 6    grain cell in canvas units (0.6…4)
uniform float uSoft;     // 7    0 hard cells … 1 soft blobs
uniform float uClump;    // 8    0…1 share of a coarser layer (clumping of grains)
uniform float uChroma;   // 9    0 mono film grain … 1 coloured sensor noise
uniform float uLuma;     // 10   brightness of what lies below (0…1): film grain is strongest in the mid-tones
uniform float uFlicker;  // 11   0…1 exposure flicker per frame (1 → ±4 %)
uniform float uDust;     // 12   0…1 dust and lint
uniform float uScratch;  // 13   0…1 vertical scratches
uniform float uVignette; // 14   0…1 darker corners
uniform float uWarm;     // 15   0…1 warm cast of old print stock
uniform sampler2D uTemplate; // AV1-style grain template 82×73, red channel = 0.5 + value/6 (value ≈ N(0,1))

out vec4 fragColor;

float hash13(vec3 p) {
  vec3 p3 = fract(p * .1031);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p) {
  vec3 p3 = fract(p * vec3(.1031, .1030, .0973));
  p3 += dot(p3, p3.yxz + 33.33);
  return fract((p3.xxy + p3.yxx) * p3.zyx);
}

// three independent N(0,1) values (Box-Muller)
vec3 gauss3(vec3 key) {
  vec3 a = hash33(key);
  float b = hash13(key + vec3(17.1, 5.3, 9.7));
  float r1 = sqrt(-2.0 * log(max(a.x, 1e-4)));
  float r2 = sqrt(-2.0 * log(max(a.z, 1e-4)));
  return vec3(r1 * cos(6.2831853 * a.y), r1 * sin(6.2831853 * a.y), r2 * cos(6.2831853 * b));
}

const vec2 TEMPLATE = vec2(82.0, 73.0);

float templateAt(vec2 texel) {
  return (texture(uTemplate, (texel + 0.5) / TEMPLATE).r - 0.5) * 6.0;
}

// value of one block's chunk of the template at grain pixel `pos`; the chunk is 34×34 (32 + 2 px overlap)
float blockVal(vec2 pos, vec2 blk, float seed) {
  vec3 h = hash33(vec3(mod(blk, 251.0), seed));
  vec2 off = floor(vec2(h.x * 48.99, h.y * 39.99));
  return templateAt(pos - blk * 32.0 + off);
}

// AV1 grain at grain pixel `pos`: block offset per frame, 2 px overlap with the left and upper block (weights 27/17, 17/27 of 32)
float av1Grain(vec2 pos, float seed) {
  vec2 b = floor(pos / 32.0);
  vec2 l = pos - b * 32.0;
  float v = blockVal(pos, b, seed);
  if (l.x < 2.0 && b.x > 0.0) {
    float o = blockVal(pos, b - vec2(1.0, 0.0), seed);
    float wo = l.x < 1.0 ? 0.84375 : 0.53125, wn = l.x < 1.0 ? 0.53125 : 0.84375;
    v = (wo * o + wn * v) / sqrt(wo * wo + wn * wn);
  }
  if (l.y < 2.0 && b.y > 0.0) {
    float o = blockVal(pos, b - vec2(0.0, 1.0), seed);
    float wo = l.y < 1.0 ? 0.84375 : 0.53125, wn = l.y < 1.0 ? 0.53125 : 0.84375;
    v = (wo * o + wn * v) / sqrt(wo * wo + wn * wn);
  }
  return v;
}

// three channels: luma grain and two more draws for colour noise, each with its own block offsets
vec3 av1Field(vec2 frag, float cell, float seed) {
  vec2 pos = floor(frag / cell);
  return vec3(av1Grain(pos, seed), av1Grain(pos, seed + 17.0), av1Grain(pos, seed + 41.0));
}

// cell noise with variance 1; cell indices wrapped to 251 (prime) to keep hash inputs small on every precision
vec3 grainField(vec2 p, float cell, float soft, float seed) {
  vec2 q = p / cell;
  vec2 i = floor(q);
  vec2 f = q - i;
  vec2 w = mix(step(0.5, f), smoothstep(0.0, 1.0, f), soft);
  float w00 = (1.0 - w.x) * (1.0 - w.y), w10 = w.x * (1.0 - w.y), w01 = (1.0 - w.x) * w.y, w11 = w.x * w.y;
  vec2 i0 = mod(i, 251.0), i1 = mod(i + 1.0, 251.0);
  vec3 g = gauss3(vec3(i0, seed)) * w00 + gauss3(vec3(i1.x, i0.y, seed)) * w10
         + gauss3(vec3(i0.x, i1.y, seed)) * w01 + gauss3(vec3(i1, seed)) * w11;
  return g / sqrt(w00 * w00 + w10 * w10 + w01 * w01 + w11 * w11);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  vec3 add = vec3(0.0);   // signed light added to what lies below
  float dark = 0.0;       // extra darkening (0…1)

  // grain: fine layer + clump layer, variance kept; luma/chroma split
  if (uGrain > 0.0) {
    vec3 g1 = av1Field(frag, uCell, uSeed);
    vec3 g2 = av1Field(frag, uCell * 2.6, uSeed + 31.0);
    vec3 g = g1 * sqrt(1.0 - uClump) + g2 * sqrt(uClump);
    float l = (g.x + g.y + g.z) * 0.57735027;
    vec3 gc = (g - vec3(l * 0.57735027)) * 1.2247449;
    vec3 gn = sqrt(1.0 - uChroma) * vec3(l) + sqrt(uChroma) * gc;
    // AV1 scaling function: piecewise linear in the brightness, strongest in the mid-tones, weak in shadows and highlights
    float y = clamp(uLuma, 0.0, 1.0);
    float resp = y < 0.25 ? mix(0.55, 0.9, y / 0.25) : (y < 0.5 ? mix(0.9, 1.15, (y - 0.25) / 0.25) : (y < 0.75 ? mix(1.15, 0.85, (y - 0.5) / 0.25) : mix(0.85, 0.5, (y - 0.75) / 0.25)));
    add += gn * uGrain * 0.11 * resp;
  }

  // exposure flicker: random per frame plus slow drift, ±4 % at most (research §3: 40 % looks kitschy)
  if (uFlicker > 0.0) {
    float fl = (hash13(vec3(uSeed, 3.7, 1.3)) - 0.5) * 0.06 + 0.015 * sin(uTime * 0.9);
    add += vec3(fl * uFlicker);
  }

  // dust: rare specks, one chance per 48 px cell and frame; dark (dirt) or bright (holes in the emulsion)
  if (uDust > 0.0) {
    vec2 ci = floor(frag / 48.0);
    vec3 h = hash33(vec3(mod(ci, 251.0), uSeed + 7.0));
    if (h.x < uDust * 0.05) {
      vec2 ctr = (ci + 0.2 + 0.6 * h.yz) * 48.0;
      float r = mix(0.8, 3.0, h.y * h.y);
      float a = smoothstep(r, r * 0.4, length(frag - ctr)) * (0.25 + 0.45 * h.z);
      add += vec3(h.z > 0.35 ? -a : a * 0.8);
    }
  }

  // scratches: up to three thin vertical lines, they stay ~1 s and wander slightly
  if (uScratch > 0.0) {
    for (int k = 0; k < 3; k++) {
      float kk = float(k);
      vec3 h = hash33(vec3(uSlow, kk * 7.1, 3.1));
      if (h.x < uScratch * 0.5) {
        float x = h.y * uSize.x + 1.5 * sin(uTime * 2.0 + h.z * 6.2831853);
        float line = smoothstep(0.6 + h.z, 0.0, abs(frag.x - x));
        float gap = step(0.2, hash13(vec3(floor(frag.y / 24.0), uSlow + kk, 9.0)));
        add += vec3(line * gap * (0.10 + 0.18 * h.y));
      }
    }
  }

  // vignette and warm cast
  if (uVignette > 0.0) {
    vec2 d = uv - 0.5;
    dark += uVignette * 0.45 * smoothstep(0.25, 0.75, dot(d, d) * 2.0);
  }

  // Overlay over unknown content: positive light as white, negative as black, both premultiplied; warm cast as tint.
  float lum = dot(add, vec3(0.3333));
  vec3 col = vec3(0.0);
  float a = 0.0;
  if (lum >= 0.0) {
    col = clamp(add, 0.0, 1.0);
    a = clamp(max(max(col.r, col.g), col.b), 0.0, 1.0);
  } else {
    a = clamp(-lum, 0.0, 1.0);
  }
  a = clamp(a + dark, 0.0, 1.0);
  vec4 o = vec4(col, a);
  if (uWarm > 0.0) {
    vec4 w = vec4(vec3(0.42, 0.25, 0.05) * uWarm * 0.10, uWarm * 0.10);
    o = o + w * (1.0 - o.a);
  }
  fragColor = o;
}
