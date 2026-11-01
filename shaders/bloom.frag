// fasan_ui – glow, halation and light bleeding on rendered content (ImageFilter.shader, Impeller only). MPL-2.0
// Engine-provided uniforms for ImageFilter shaders: floats 0/1 = image size, sampler 0 = input image.
// Under OpenGLES the texture y axis is flipped (docs.flutter.dev/ui/design/graphics/fragment-shaders).
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;          // floats 0, 1 (engine)
uniform sampler2D uTexture;  // sampler 0 (engine)
uniform float uGlow;         // float 2
uniform float uHalation;     // float 3
uniform float uBleed;        // float 4
uniform float uRadius;       // float 5: spread in px

out vec4 fragColor;

vec4 tex(vec2 uv) {
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif
  return texture(uTexture, uv);
}

// Only highlights spread (threshold like a film's toe); premultiplied input.
vec3 bright(vec4 s) {
  vec3 c = s.a > 0.0 ? s.rgb / s.a : vec3(0.0);
  float l = dot(c, vec3(0.2126, 0.7152, 0.0722));
  return c * smoothstep(0.6, 0.95, l) * s.a;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec4 base = tex(uv);
  vec2 px = 1.0 / uSize;
  vec3 glow = vec3(0.0);
  vec3 halo = vec3(0.0);
  for (int i = 0; i < 8; i++) {
    float a = float(i) * 2.39996;  // golden angle spreads the taps evenly
    float r = 0.4 + float(i) / 8.0;
    vec2 o = vec2(cos(a), sin(a)) * px * uRadius * r;
    glow += bright(tex(uv + o));
    halo += bright(tex(uv + o * 2.4));
  }
  glow /= 8.0;
  halo /= 8.0;
  vec3 bleed = vec3(0.0);
  for (int i = -2; i <= 2; i++) {
    bleed += bright(tex(uv + vec2(float(i) * px.x * uRadius * 1.4, 0.0)));
  }
  bleed /= 5.0;
  // Halation: light scattered back from the film base is reddish-orange.
  vec3 add = glow * uGlow * 1.3 + halo * vec3(1.0, 0.38, 0.2) * uHalation * 1.8 + bleed * vec3(1.0, 0.85, 0.62) * uBleed * 1.2;
  vec3 c = base.rgb + add;
  float alpha = clamp(max(base.a, max(add.r, max(add.g, add.b))), 0.0, 1.0);
  fragColor = vec4(min(c, vec3(alpha)), alpha);
}
