// fasan_ui – film grain overlay, drawn with Paint.shader (no input image). MPL-2.0
// Flutter fragment shader rules: docs.flutter.dev/ui/design/graphics/fragment-shaders
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;     // float 0, 1
uniform float uTime;    // float 2: seconds; frozen when motion is off or power is saved
uniform float uAmount;  // float 3: 0..1 (user setting)
uniform float uScale;   // float 4: grain cell in FlutterFragCoord units (local; logical vs physical nicht geprüft)

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(443.897, 441.423));
  p += dot(p, p.yx + 19.19);
  return fract((p.x + p.y) * p.x);
}

void main() {
  vec2 cell = floor(FlutterFragCoord().xy / uScale);
  float frame = floor(uTime * 24.0);  // film runs at 24 frames per second
  float n1 = hash(cell + frame * vec2(17.0, 31.0));
  float n2 = hash(floor(cell * 0.5) + 7.3 + frame);
  float g = mix(n1, n2, 0.35) - 0.5;  // -0.5 .. 0.5, two octaves look softer than white noise
  // 0.1 used 0.18 (≤ 4.5 % cover at the default 0.25): not noticeable (Nutzer 02.11.). Now ≤ 12 % at 0.25.
  float a = uAmount * 0.48 * abs(g) * 2.0;
  vec3 c = g > 0.0 ? vec3(1.0) : vec3(0.0);
  fragColor = vec4(c * a, a);  // premultiplied
}
