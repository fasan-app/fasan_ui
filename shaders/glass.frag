// fasan_ui – Liquid-Glass edge: refraction at a rounded bevel, specular light and Fresnel (BackdropFilter + ImageFilter.shader).
// MPL-2.0. Basis: docs/recherche/2026-11-02-echtes-glas-flutter.md §4 and §6 (SDF of a rounded rectangle, refract() through
// a curved bevel, clamp UVs because GLES reads black outside the texture, premultiplied output).
// Flutter 3.47: the engine sets uSize (first vec2) and uBackdrop (first sampler); Dart sets floats from index 2 on.
// No y flip: since 3.47 the GLES input is no longer mirrored (Issue #186554, PR #186556/#187316). The earlier bloom shader
// still flipped – the likely cause of the upside-down emulator picture. A start-up probe (FasanGlassProbe) checks the
// orientation on every device before this shader is used.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uSize;        // engine: size of the input (= clip area)
uniform float uRadius;     // 2  corner radius (px)
uniform float uBevel;      // 3  width of the refracting rim (px)
uniform float uThickness;  // 4  how far the rim shifts the background (px)
uniform float uIor;        // 5  index of refraction (~1.5)
uniform vec2 uLight;       // 6,7 light direction (normalised, screen space, y down)
uniform float uSpec;       // 8  specular strength
uniform float uTintA;      // 9  tint opacity
uniform vec3 uTint;        // 10..12 tint colour (straight, not premultiplied)
uniform sampler2D uBackdrop;

out vec4 fragColor;

float sdRound(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 b = 0.5 * uSize;
  vec2 p = frag - b;
  float r = min(uRadius, min(b.x, b.y));
  float d = sdRound(p, b, r);
  vec2 e = vec2(1.0, 0.0);
  vec2 n = normalize(vec2(sdRound(p + e.xy, b, r) - sdRound(p - e.xy, b, r),
                          sdRound(p + e.yx, b, r) - sdRound(p - e.yx, b, r)) + 1e-5);
  float t = clamp(-d / max(uBevel, 1.0), 0.0, 1.0);          // 0 at the rim, 1 inside
  float h = sqrt(max(1.0 - (1.0 - t) * (1.0 - t), 0.0));    // height of a quarter-round bevel
  vec3 N = normalize(vec3(n * (1.0 - t), max(h, 1e-3)));
  vec3 R = refract(vec3(0.0, 0.0, -1.0), N, 1.0 / uIor);
  vec2 off = R.xy / max(-R.z, 1e-3) * uThickness;
  vec2 uv = clamp((frag + off) / uSize, 0.5 / uSize, 1.0 - 0.5 / uSize);
  vec4 c = texture(uBackdrop, uv);
  // light on the rim: bright on the light side, a weaker counter-light opposite (light passing through)
  float rim = pow(1.0 - h, 2.0);
  float spec = uSpec * rim * (max(dot(n, uLight), 0.0) + 0.35 * max(dot(n, -uLight), 0.0));
  float fres = 0.04 + 0.96 * pow(1.0 - h, 5.0);
  vec3 rgb = mix(c.rgb, uTint * c.a, uTintA) + vec3(spec + 0.18 * fres * uSpec) * c.a;
  fragColor = vec4(min(rgb, vec3(c.a)), c.a);
}
