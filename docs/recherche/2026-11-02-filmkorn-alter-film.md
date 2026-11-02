# Filmkorn, Bildrauschen und „alter Film“ im Fragment-Shader – Recherche 02.11.2026

Nur lesend recherchiert (WebSearch/WebFetch), nichts gesendet. Etwa 35 Abrufe.
Kennzeichnung: **[Beleg]** = Quelle gelesen. **[Abgeleitet]** = eigene Rechnung aus Belegen. **[Nicht geprüft]** = Vorschlag oder Wissen ohne gelesene Quelle.

## Kurzfassung

- Echtes Korn ist je Bild neu und je Ort unabhängig. Es wandert nie. Also: Hash aus (Pixel-/Zellkoordinate, Bild-Seed), nie eine verschobene Textur. [Beleg: Wikipedia Film grain; AV1 nutzt zufällige Offsets je Block und Bild]
- Film: überwiegend Helligkeitskorn, farbneutral, Größe hängt von der Filmempfindlichkeit. Digital: Pixelgröße, dazu Farbrauschen, im Blau am stärksten. [Beleg: Unique Photo]
- Digitale Stärke folgt Shot-Noise (Standardabweichung ~ Wurzel des Signals) plus Grundrauschen in Schatten. Filmkorn ist in den Mitten am stärksten. [Beleg: Wikipedia Image noise; Resolve „Glockenform“; Boolean-Modell abgeleitet]
- Newson-Modell (Boolean-Modell + Gauß-Filter) ist laut Autoren „weit von Echtzeit“. Für Handys braucht es eine Näherung: Gauß-Zellrauschen. [Beleg: IPOL 2017]
- AV1 macht es genauso: Gauß-Korn (AR-Modell Lag 0–3), addiert mit helligkeitsabhängiger Skalierung f(Y). [Beleg: Norkin DCC 2018]
- Hash ohne `sin`, ohne große Zahlen (Hoskins `fract`-Hash). `sin`-Hashes sind GPU-abhängig. [Beleg: Jarzynski/Olano; Medium-Artikel]
- Flutter: `uniform float`, nur `sampler2D`, keine unsigned ints/Bools. Ganzzahl-Hashes (PCG) daher riskant. Float-Hash nutzen. [Beleg: Flutter-Doku]
- Alter Film = Flackern, Staub, Kratzer, Bildstandwackeln, Vignette, Halation, Farbstich. Profi-Werkzeuge zeigen, welche Regler üblich sind (Tabelle 4).
- Kitsch vermeiden: Alles nur wenige Prozent, selten, mit Zufall. Das 40-%-Flackern des Beispiel-Shaders (Faktor 0,6–1,0) ist zu stark. [Beleg: OldMovieFP.glsl; Bewertung eigen]
- Kosten: Hash-Korn ist ALU-leicht. Der Backdrop-Zugriff (Textur lesen) kostet Bandbreite. Zeichne mit 24 Hz neu. [Teils Beleg, Messwerte fehlen]
- Fasan-Regeln: Sucher nie verdecken, „Animationen entfernen“ befolgen. Darum Standard = aus oder sehr leise; Flackern streng begrenzen.
- Offen: echte Messung auf Zielgeräten, Präzisionsverhalten unter Impeller, Signed-Int-Unterstützung.

## 1. Physik und Modelle

### 1.1 Filmkorn real
- Korn entsteht aus Silberteilchen oder Farbwolken. Größere Kristalle = empfindlicher = körniger. [Beleg: https://en.wikipedia.org/wiki/Film_grain]
- Körner sind zufällig verteilt und verschieden groß; das Muster ist nicht regelmäßig. [Beleg: ebd.]
- Körnigkeit (RMS granularity) misst die Dichteschwankung. Messung mit 48-µm-Blende bei Dichte 1,0; Angabe oft ×1000. [Beleg: ebd.]

### 1.2 Newson et al. 2017 (Boolean-Modell)
- Korn = Vereinigung von Scheiben, Mittelpunkte aus Poisson-Prozess; Radius mit Mittel µr und Streuung σr, konstant oder log-normal. [Beleg: https://www.ipol.im/pub/art/2017/192/article.pdf]
- Intensität: λ = (1/E[πr²]) · log(1/(1−ũ)), ũ = Grauwert in [0,1). [Beleg: ebd.]
- Danach Gauß-Filter, Standard σ = 0,8 Ausgabepixel; Testwerte µr 0,03–0,3, Abbildungen mit 0,1 Eingabepixel; σr/µr 0,1–0,9. [Beleg: ebd.]
- Monte Carlo mit N Zufallsversätzen je Pixel. Autoren: „far from being real-time“; 512×512 braucht 2,4 s (Pixel-Methode, CPU). [Beleg: ebd.]
- [Abgeleitet] Vor dem Filter ist jeder Punkt mit Wahrscheinlichkeit ũ bedeckt (Bernoulli). Varianz ũ(1−ũ), am größten bei Mittelgrau. Die Quelle sagt das nicht ausdrücklich. Es passt zur Glockenform im Reglerabschnitt.

### 1.3 AV1 Film Grain Synthesis
- Autoregressives Modell, Lag L = 0…3. L = 0 ist reines Gauß-Rauschen. Chroma hat einen Zusatzkoeffizienten zur Luma-Korrelation. [Beleg: https://norkin.org/pdf/DCC_2018_AV1_film_grain.pdf]
- Skalierung stückweise linear f(Y), 256-Werte-Tabelle. Synthese: Y' = clip(Y + (G·f(Y) + Rundung) >> shift). Also additiv, in Codewerten. [Beleg: ebd.]
- Chroma-Skalierung aus Luma-Mittel: Index u = b·Cb + d·Yav + h. [Beleg: ebd.]
- Korn-Vorlagen 64×64 (Luma) und 2×32×32 (Chroma), in 32×32-Blöcken mit zufälligem Offset aus einem 16-Bit-LFSR, Überlappung 2 Pixel. [Beleg: ebd.]
- Folgerung: AV1 spart Rechenzeit durch Vorlagen. Ein Shader kann stattdessen je Pixel hashen. Das ist keine Verschiebung einer Textur. [Abgeleitet]

### 1.4 Digitales Sensorrauschen
- Shot-Noise: Poisson, Standardabweichung wächst mit Wurzel des Signals, je Pixel unabhängig. [Beleg: https://en.wikipedia.org/wiki/Image_noise]
- Lesenoise: etwa Gauß, konstanter Boden, dominiert Schatten (niedriges SNR). [Beleg: ebd.]
- Poisson-Gauß-Modell mit Varianz affin im Signal (a·y + b): Foi et al. 2008. Volltext nicht abrufbar (Allowlist), Aussage aus Wissen. [Nicht geprüft]
- Luma-Rauschen ähnelt Filmkorn, Farbrauschen ist störender. [Beleg: Wikipedia Image noise]
- Film vs. digital: Filmkorn ist farbneutral, überwiegend Helligkeit, ohne Bänder/Muster; digitales Rauschen hat Farbanteil, am sichtbarsten im Blau, immer Pixelgröße. [Beleg: https://www.uniquephoto.com/community/qa/whats-the-difference-between-high-iso-digital-noise-and-film-grain]

### 1.5 Schluss für den Shader
- Eine Gauß-Zufallszahl je Zelle, mit Zellgröße = Korngröße. Additiv in Anzeigewerten wie AV1.
- Stärke nach Helligkeit: Film = Glocke (Mitten stark), Sensor = Wurzel mit Schattenboden. Regler „Sensor“ mischt beide.
- Farbanteil gering (Standard 20 %), Rest Luma.

## 2. Shader-Technik

### 2.1 Zeitlich unabhängig
- Hash-Eingang = (Zellkoordinate, Seed). Seed je Bild neu, am besten aus Dart (`Random`) als Uniform, nicht aus großem Zähler. So gibt es keine Genauigkeitsprobleme und keine Wiederholung.
- Nie `uv + time` verschieben. Das gäbe die „wandernde Textur“, die der Nutzer nicht will.
- Optional: zeitliche Korrelation t (0…1) = Mischung zweier Seeds mit √t und √(1−t). Doppelte Kosten. Echtes Korn hat t = 0. [Abgeleitet]

### 2.2 Hash
- Empfehlung der Forschung: PCG (pcg3d/pcg4d, xxhash32). `sin`-Hash („trig“) zeigt Bänder und Wiederholung. [Beleg: https://www.jcgt.org/published/0009/03/02/paper.pdf]
- Sin-Hash liefert je GPU andere Werte; nur uint-Hashes waren überall gleich. [Beleg: https://arugl.medium.com/float-precision-on-gpu-bugs-features-178ddd030f]
- Flutter-Shader: unsigned ints und Bools nicht unterstützt; Signed-Int-Support nicht dokumentiert. PCG (nutzt `uint`) fällt damit aus. [Beleg: https://docs.flutter.dev/ui/design/graphics/fragment-shaders]
- Gewählt: Hoskins „Hash without Sine“ (hash13/hash33): `fract(p*.1031)`, `dot`, `fract`. Kein `sin`, kleine Zahlen. MIT-Lizenz. [Beleg: https://gist.github.com/davidar/5f9677a0ccfbd63d7a8657ad9af3a856] Verteilungsgüte gegen PCG: [Nicht geprüft]
- Eingänge klein halten (Zellindex bis einige Tausend). Seed unter 64.

### 2.3 Präzision
- Fragment-`highp` ist in GLSL ES optional; auf alten Handys (ca. 2011–2013) fehlt es. `mediump` kann echt niedriger sein. [Beleg: https://webglfundamentals.org/webgl/lessons/webgl-qna-when-to-choose-highp--mediump--lowp-in-shaders.html]
- Flutter: Präzisionshinweise werden bei Skia ignoriert; zu Impeller sagt die Doku nichts. [Beleg: Flutter-Doku] Darum: `precision highp float;` schreiben und trotzdem nichts Großes hashen. Verhalten unter Impeller/Vulkan/GLES auf Zielgeräten: [Nicht geprüft]
- Zahlenwerte der Mindestbereiche (mediump ±2^14, 10 Bit Mantisse) stehen nicht in den gelesenen Seiten. Spec-Abschnitt 4.5.2 nicht gelesen. [Nicht geprüft]

### 2.4 Gauß-Verteilung
- Box-Muller aus zwei Gleichverteilten: n = √(−2 ln u1) · cos(2π u2); `u1` auf ≥ 1e-4 klemmen. [Nicht geprüft als Quelle; Standardformel]
- Billiger: Summe von 4 Gleichverteilten, minus 2, mal √3 (Varianz 1). [Abgeleitet]
- Kosten beider Wege sind klein gegen den Texturzugriff. Messung fehlt. [Nicht geprüft]

### 2.5 Korngröße, Klumpen, Weichheit
- Größe ≥ 1 Gerätepixel. Feiner als 1 px geht nicht; dann Stärke senken (Mittelung mehrerer Körner senkt die Streuung). [Abgeleitet]
- Newson: Gauß-Filter σ ≈ 0,8 Ausgabepixel macht das Korn weich. [Beleg: IPOL] Im Shader: bilineare Mischung der vier Nachbarzellen. Wichtig: danach durch √(Σw²) teilen, sonst sinkt die Streuung. [Abgeleitet]
- Klumpen/Roughness: zweite, gröbere Lage (~2,5× Zellgröße), varianzerhaltend gemischt: `g1·√(1−k) + g2·√k`. Lightroom: Roughness steuert, wie gleichmäßig das Korn ist. [Beleg: Adobe Camera Raw Hilfe] Genaue Adobe-Umsetzung unbekannt.
- Einheit von `FlutterFragCoord()`: „lokale Koordinaten“. Ob logische oder physische Pixel, steht nicht in der Doku. Mit `devicePixelRatio` auf dem Gerät prüfen. [Beleg + Nicht geprüft]

### 2.6 Farbe vs. mono
- Aus drei Gauß-Werten: Luma `l = (g.x+g.y+g.z)/√3`, Chroma `gc = (g − l/√3)·√1,5`. Mischung `√(1−c)·l + √c·gc`. Varianz bleibt 1, Luma und Chroma unabhängig. [Abgeleitet]
- Standard Chroma 20 % (Vindral: Luma 80 %, Chroma 20 %). [Beleg: https://composer.docs.vindral.com/docs/film-grain]

### 2.7 Helligkeitsabhängige Stärke
- Resolve (Grain-Knoten): Kurven je Kanal, „Glockenform als realistischer Start“. [Beleg: https://www.steakunderwater.com/VFXPedia/__man/Resolve18-6/DaVinciResolve18_Manual_files/part2310.htm]
- Vindral-Standards: Mittelpunkt 50 %, Schattenschutz 30 %, Lichterschutz 0 %. [Beleg: ebd. Vindral]
- Sensor: σ(Y) = √(b + (1−b)·Y), auf 1 bei Y = 1 normiert. [Abgeleitet aus Varianz = a·y + b]
- Luma Y: Rec.709-Gewichte 0,2126/0,7152/0,0722. [Nicht geprüft]

## 3. Merkmale „alter Film“

Werte mit [Beleg] stammen aus Reglervoreinstellungen von Werkzeugen; Einheiten dort oft nicht erklärt. Alle „Vorschlag“-Werte sind [Nicht geprüft].

| Merkmal | Was Quellen sagen | Vorschlag für Fasan |
|---|---|---|
| Bildrate | Stummfilm 16–24 fps, schwankend. 24 fps seit Tonfilm. Projektor-Blenden zeigen jedes Bild 2× (48/s) oder 3× (72/s). 18 fps steht dort nicht. [Beleg: https://en.wikipedia.org/wiki/Frame_rate] | Korn mit 24 Hz neu würfeln. Wahlweise 12–30. |
| Flackern | Sapphire FilmRoll: Flicker 1, Rand Amp 1, Rand Freq 10, Wave Amp 0, Wave Freq 5 (Einheit offen). [Beleg: https://borisfx.com/documentation/sapphire/ofx/filmroll/] Beispiel-Shader: Faktor 0,6–1,0, Dreieckswelle. [Beleg: OldMovieFP.glsl] Kdenlive: Helligkeit rauf/runter in % der Bilder, plus langsame „Uneven Develop“-Zyklen. [Beleg: https://docs.kdenlive.org/en/effects_and_filters/video_effects/stylize/oldfilm.html] | Zufall je Bild ±2–4 % Helligkeit, dazu langsame Drift ±1 %. Nie 40 %. |
| Staub | Sapphire: Dust Density 60, Size 1, Opacity 0,8, Vary Opacity 0,5. Dunkle Flecken multiplizieren, helle addieren. [Beleg: Sapphire; OldMovieFP.glsl] Maxon Retrograde: Dust, Hair, Splotch mit Count/Scale. [Beleg: https://help.maxon.net/rg/en-us/Content/html/retrograde.html.md] | 0–6 Flecken je Bild, Radius 1–3,5 px, Deckkraft 0,3–0,8; 1–3 Bilder Lebensdauer. |
| Kratzer | Sapphire: 5 Kratzer, schwarz 1, weiß 0,1, Breite 0,15, Lücken 0,28, Rauheit 1. [Beleg: Sapphire] Senkrechte Linien, mit Lücken. | 0–3 senkrechte Linien, 1–2 px breit, Alpha 0,15–0,4, bleiben 0,5–2 s, leicht wackelnd. |
| Bildstandwackeln | Kdenlive Gate Weave: Zufallsversatz, Maximum je Achse „10“, Bruchteile ergeben sanfte Mischung. [Beleg: https://docs.kdenlive.org/en/effects_and_filters/video_effects/motion/gate_weave.html] Sapphire: Weave Amount 1, Frequency 0,1. Kdenlive Old Film: senkrechter Versatz nur bei einem Prozentsatz der Bilder. | 0–2 px, glatter Zufallsgang aus Dart. Standard 0 für die UI. |
| Vignette | Camera Raw: Amount, Midpoint, Roundness, Feather. [Beleg: https://helpx.adobe.com/sg/camera-raw/desktop/edit-and-enhance-images/tone-and-color/vignette-grain-effects-camera-raw.html] | Abdunkeln 10–30 %, weicher Verlauf. |
| Halation | Rot-orange Höfe um helle Lichter, weiß bei S/W. Licht streut im Träger zurück und belichtet die Schicht erneut; fehlt die Lichthofschutzschicht (Remjet), wird es stärker. [Beleg: https://www.analog.cafe/r/halation-in-film-photography-i3q4; https://www.dehancer.com/learn/article/halation] Dehancer: Schwelle (Source Limiter), Radius (Local Diffusion), Farbton, Stärke (Impact). | Phase 2. Helle Pixel über Schwelle, 8–12 Taps weich, Tönung Rot-Orange, 0–25 %. Tönungswerte [Nicht geprüft]. |
| Farbstich/Verblassen | Sepia-Rampe über Luma im Beispiel-Shader. [Beleg: OldMovieFP.glsl] | Warmer Stich 0–20 %, Schwarz leicht anheben 0–4 %. |

Warum nicht kitschig:
- Seltene, zufällige Ereignisse statt Dauerschleife. [Abgeleitet]
- Staub und Kratzer nie in der Bildmitte des Suchers (Fasan-Regel „Sucher nie verdecken“).
- Flackern gering halten. Die WCAG-Schwelle (drei Blitze pro Sekunde) konnte nicht geladen werden (Allowlist). 2–4 % bei 24 Hz liegt weit darunter. Schwellenwert selbst [Nicht geprüft]; vor Release gegen WCAG 2.3.1 prüfen.
- „Animationen entfernen“: Seed einfrieren, Flackern/Wackeln/Kratzer aus. API-Name in Flutter [Nicht geprüft].

## 4. Regler der Profi-Werkzeuge

| Werkzeug | Regler | Bereiche, soweit belegt |
|---|---|---|
| Lightroom / Camera Raw | Amount, Size, Roughness | Keine Zahlen auf der Hilfeseite. Size ab 25 % kann das Bild etwas weichzeichnen. Roughness: niedrig = gleichmäßig. [Beleg: Adobe Hilfe] |
| DaVinci Resolve (Grain-Knoten) | Power, RGB Difference, Softness, Size, Spacing, Aspect Ratio, Spread-Kurven je Kanal | Keine Zahlen. Softness niedrig = scharfes, gröberes Korn. [Beleg: Resolve-Handbuch 18.6] Der „Film Grain“-OFX-Effekt wurde nicht gefunden. |
| FilmConvert Nitrate | 8 Korngrößen (8 mm … 35 mm Vollformat) aus Scans, Amount, Softness, Saturation, Tonwertantwort Lichter/Mitten/Schatten | Keine Zahlen. [Beleg: https://jonnyelwyn.co.uk/film-and-video-editing/understanding-film-emulation-with-filmconvert-nitrate/] |
| Dehancer | Grain-Regler nicht gelesen. Halation: Source Limiter, Background Gain, Smoothness, Local/Global Diffusion, Amplify, Hue, Blue Comp., Impact | Keine Zahlen. [Beleg: Dehancer Halation] |
| Vindral Film Grain | Amount 0–100 % (Start 20–30), Size 10–100, Softness 0–100, Luminance 80, Chroma 20, Chroma Saturation 100 (200 = sehr bunt), Midpoint 50, Shadow Protection 30, Highlight Protection 0, Blend (Overlay/Soft Light/Add/Linear), Animated, Seed, R/G/B-Amount 100 | Als einzige mit Zahlen. [Beleg: https://composer.docs.vindral.com/docs/film-grain] |
| Sapphire FilmRoll | Flicker, Kratzer, Staub, Weave | Zahlen siehe Abschnitt 3. [Beleg] |

Aus dem Vergleich folgt für Fasan: Amount, Size, Softness/Roughness, Luma/Chroma, Tonwertantwort (Mitte, Schatten, Lichter), Seed/Animiert, Blendmodus (nur Add vorerst). Alles als Schieber mit Feinstufe.

## 5. Leistung auf Handys

- Kein Messwert zu Flutter-Shadern auf Handys gefunden. Alle Kostenaussagen sind Richtwerte.
- Impeller kompiliert Shader beim Bauen vor, daher weniger Ruckeln durch Shader-Kompilierung. [Beleg: Flutter-Designdokument FragmentProgram, 2022; Stand heute nicht neu geprüft]
- `FragmentShader`-Objekte wiederverwenden. [Beleg: Flutter-Doku]
- Arm (GDC 2018): Wechsel von 1080p auf 720p halbierte die Zeit (10 ms → 5 ms) bei einem Hintergrund-Pass. Zusätzlicher Bandbreitenbedarf (RGB24-Ziel) verdoppelte die Bandbreite. [Beleg: https://community.arm.com/developer/tools-software/graphics/b/blog/posts/post-processing-effects-for-mobile-at-gdc18]
- Ableitung für Fasan [Nicht geprüft]:
  - Variante ohne Backdrop-Zugriff (Overlay mit Blendmodus) spart den Texturzugriff, kann aber keine helligkeitsabhängige Stärke. Blendmodus-Verhalten in Flutter nicht geprüft.
  - Bei Korngröße ≥ 2 px lohnt eine Zeichnung in halber Auflösung mit Hochskalierung. Der Weg in Flutter (kleine Ebene + Skalierung) ist nicht geprüft.
  - Neu zeichnen nur mit 24 Hz (Ticker), sonst nichts. Bei statischem Bild dahinter lohnt `RepaintBoundary` (nicht geprüft).
  - Stufen: „Leicht“ = ein Hash je Pixel, keine Interpolation, Summe-Gauß. „Voll“ = Bilinear + Klumpen + Box-Muller. Je Stufe eigene .frag-Datei, da Schleifen und Verzweigungen in der Flutter-Doku nicht erwähnt sind.
  - `ImageFilter.shader` nur Impeller; auf OpenGLES Textur-y spiegeln. [Beleg: Flutter-Doku]

## 6. Shader-Vorschlag (Pseudocode GLSL, nicht kompiliert, nicht getestet)

Dateien: `grain_full.frag` (Voll). `grain_lite.frag` leitet sich durch Streichen ab (Hinweise im Code).
Aufbau nach Flutter-Doku: `u_size` und `u_texture` setzt die Engine (Float-Index 0/1, Sampler 0); eigene Floats beginnen bei Index 2. Reihenfolge der Deklaration = Reihenfolge von `setFloat`.

```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>
precision highp float;

// --- von der Engine (ImageFilter.shader), nicht aus Dart setzen ---
uniform vec2 u_size;
uniform sampler2D u_texture;

// --- aus Dart ---
uniform vec2  uSeed;        // x: je Bild neu (0..64), y: langsam (alle 2-4 Bilder)
uniform float uSeedSlow;    // 0..64, wechselt alle 0.5-2 s (Kratzer)
uniform float uTime;        // Sekunden, nur für langsame Drift
uniform vec2  uWeavePx;     // Versatz in px, glatter Zufallsgang aus Dart

// Korn
uniform float uGrain;       // 0..0.30  Std.abw. in Anzeigewerten   Standard 0.06
uniform float uSize;        // 1..6 px  Zellgröße                    Standard 1.6
uniform float uSoft;        // 0..1     Weichheit (Interpolation)    Standard 0.5
uniform float uClump;       // 0..1     Klumpen (grobe Lage)         Standard 0.25
uniform float uChroma;      // 0..1     Farbanteil                   Standard 0.2
uniform float uMid;         // 0.2..0.8 Mittelpunkt Film-Glocke      Standard 0.5
uniform float uShadowProt;  // 0..1     weniger Korn in Schatten     Standard 0.3
uniform float uHighProt;    // 0..1     weniger Korn in Lichtern     Standard 0.0
uniform float uSensor;      // 0..1     0 = Film, 1 = Sensor-Wurzel  Standard 0.0
uniform float uReadFloor;   // 0..1     Schattenboden b              Standard 0.25

// Alter Film
uniform float uFlicker;     // 0..0.08  Zufall je Bild               Standard 0.0 (Profil: 0.03)
uniform float uDrift;       // 0..0.04  langsame Drift               Standard 0.0 (Profil: 0.01)
uniform float uDust;        // 0..1                                  Standard 0.0 (Profil: 0.3)
uniform float uDustSize;    // 0.5..2                                Standard 1.0
uniform float uScratch;     // 0..1     Wahrscheinlichkeit je Linie  Standard 0.0 (Profil: 0.2)
uniform float uVignette;    // 0..0.5                                Standard 0.0 (Profil: 0.2)
uniform float uWarm;        // 0..0.3   warmer Stich                 Standard 0.0
uniform float uLift;        // 0..0.06  Schwarz anheben              Standard 0.0
// Phase 2: uHalation, uHalRadius, uHalThreshold (siehe Kommentar unten)

out vec4 fragColor;

// Hoskins "Hash without Sine" (MIT), Eingang klein halten
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

// drei unabhängige N(0,1)  (Lite: Summe von 4 Gleichverteilten statt Box-Muller)
vec3 gauss3(vec3 key) {
  vec3 a = hash33(key);
  float b = hash13(key + vec3(17.1, 5.3, 9.7));
  float r1 = sqrt(-2.0 * log(max(a.x, 1e-4)));
  float r2 = sqrt(-2.0 * log(max(a.z, 1e-4)));
  return vec3(r1 * cos(6.2831853 * a.y),
              r1 * sin(6.2831853 * a.y),
              r2 * cos(6.2831853 * b));
}

// Zellrauschen mit Varianz 1; soft=0 harte Zellen, soft=1 glatt
vec3 grainField(vec2 p, float cell, float soft, float seed) {
  vec2 q = p / cell;
  vec2 i = floor(q);
  vec2 f = q - i;
  vec2 w = mix(step(0.5, f), smoothstep(0.0, 1.0, f), soft);
  float w00 = (1.0 - w.x) * (1.0 - w.y);
  float w10 = w.x * (1.0 - w.y);
  float w01 = (1.0 - w.x) * w.y;
  float w11 = w.x * w.y;
  vec3 g = gauss3(vec3(i, seed)) * w00
         + gauss3(vec3(i + vec2(1.0, 0.0), seed)) * w10
         + gauss3(vec3(i + vec2(0.0, 1.0), seed)) * w01
         + gauss3(vec3(i + vec2(1.0, 1.0), seed)) * w11;
  return g / sqrt(w00 * w00 + w10 * w10 + w01 * w01 + w11 * w11); // Varianz erhalten
}

// ein Staubfleck je Zelle (48 px), Wahrscheinlichkeit ~ uDust
// Rückgabe: x = Stärke, y = +1 hell / -1 dunkel
vec2 dustLayer(vec2 frag, float seed) {
  float cs = 48.0;
  vec2 i = floor(frag / cs);
  vec3 h = hash33(vec3(i, seed));
  if (h.x > uDust * 0.06) return vec2(0.0);
  vec2 ctr = (i + 0.2 + 0.6 * h.yz) * cs;
  float r = mix(1.0, 3.5, h.y * h.y) * uDustSize;
  float a = smoothstep(r, r * 0.5, length(frag - ctr)) * (0.3 + 0.5 * h.z);
  return vec2(a, h.z > 0.35 ? -1.0 : 1.0);
}

// eine senkrechte Kratzerlinie (k = 0,1,2 von Hand ausrollen)
float scratchOne(vec2 frag, float k) {
  vec3 h = hash33(vec3(uSeedSlow, k * 7.1, 3.1));
  if (h.x > uScratch) return 0.0;
  float x = h.y * u_size.x + 0.5 * sin(uTime * 2.0 + h.z * 6.2831853);
  float w = 0.75 + h.z;                                  // px
  float line = smoothstep(w, 0.0, abs(frag.x - x));
  float gap = hash13(vec3(floor(frag.y / 24.0), uSeedSlow + k, 9.0));
  return line * step(0.25, gap) * (0.15 + 0.25 * h.y);
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / u_size;
  vec2 suv = (frag + uWeavePx) / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  suv.y = 1.0 - suv.y;
#endif
  vec3 c = texture(u_texture, suv).rgb;

  // Belichtungsflackern (Zufall je Bild + langsame Drift)
  float fl = (hash13(vec3(uSeed.x, 3.7, 1.3)) - 0.5) * 2.0 * uFlicker
           + uDrift * sin(uTime * 0.9);
  c *= 1.0 + fl;

  // helligkeitsabhängige Stärke
  float Y = dot(c, vec3(0.2126, 0.7152, 0.0722));
  float film = 1.0 - uShadowProt * (1.0 - smoothstep(0.0, uMid, Y))
                   - uHighProt * smoothstep(uMid, 1.0, Y);
  float sens = sqrt(uReadFloor + (1.0 - uReadFloor) * Y);
  float resp = mix(film, sens, uSensor);

  // Korn: feine Lage + Klumpenlage, varianzerhaltend gemischt
  vec3 g1 = grainField(frag, uSize, uSoft, uSeed.x);
  vec3 g2 = grainField(frag, uSize * 2.6, uSoft, uSeed.x + 31.0);
  vec3 g = g1 * sqrt(1.0 - uClump) + g2 * sqrt(uClump);

  // Luma/Chroma trennen (varianzerhaltend)
  float l = (g.x + g.y + g.z) * 0.57735027;
  vec3 gc = (g - vec3(l * 0.57735027)) * 1.2247449;
  vec3 gn = sqrt(1.0 - uChroma) * vec3(l) + sqrt(uChroma) * gc;

  c += gn * uGrain * resp;                      // additiv wie AV1 (Y + G*f(Y))

  // Staub (zwei Lagen: Bild-Seed und langsamer Seed)
  vec2 d1 = dustLayer(frag, uSeed.y);
  vec2 d2 = dustLayer(frag + 13.0, uSeed.x);
  c = mix(c, d1.y < 0.0 ? c * 0.4 : vec3(1.0), d1.x);
  c = mix(c, d2.y < 0.0 ? c * 0.4 : vec3(1.0), d2.x);

  // Kratzer
  c += scratchOne(frag, 0.0) + scratchOne(frag, 1.0) + scratchOne(frag, 2.0);

  // Vignette
  vec2 vc = (uv - 0.5) * vec2(u_size.x / u_size.y, 1.0);
  c *= 1.0 - uVignette * smoothstep(0.35, 0.95, length(vc));

  // Farbe: warmer Stich, angehobenes Schwarz
  c = mix(c, c * vec3(1.0, 0.92, 0.78), uWarm / 0.3);
  c = c * (1.0 - uLift) + uLift * 0.5;

  // Phase 2 Halation: ~8-12 Taps im Ring (Radius uHalRadius * u_size.y),
  // nur Pixel über uHalThreshold, Tönung ~ vec3(1.0, 0.35, 0.15), additiv.
  // Taps von Hand ausrollen.

  fragColor = vec4(clamp(c, 0.0, 1.0), 1.0);   // alpha 1: keine Vormultiplikation nötig
}
```

Hinweise zum Aufbau [alle Nicht geprüft, außer wo vermerkt]:
- Dart: Ticker mit 24 Hz. Je Tick `Random().nextDouble() * 64` in `uSeed.x`. `uSeed.y` jeden 2. bis 4. Tick. `uSeedSlow` alle 0,5–2 s. `uWeavePx` als glatter Zufallsgang, Beträge ≤ 2 px.
- `setFloat`-Reihenfolge: nach der Deklaration. Mehrteilige Typen brauchen je Komponente einen Aufruf. [Beleg: Flutter-Doku]
- „Lite“: `gauss3` durch `(sum of 4 hash) - 2) * 1.732` ersetzen; `uSoft` fest 0; kein `g2`; keine Staubebene 2.
- Mit Kamera-Sucher: Staub, Kratzer, Vignette und Wackeln aus; nur Korn.

### Wertebereiche und Standardwerte (Übersicht)

| Uniform | Bereich | Standard (Korn dezent) | Profil „Alter Film“ (Vorschlag) |
|---|---|---|---|
| uGrain | 0 – 0,30 | 0,06 | 0,10 |
| uSize (px) | 1 – 6 | 1,6 | 2,0 |
| uSoft | 0 – 1 | 0,5 | 0,6 |
| uClump | 0 – 1 | 0,25 | 0,35 |
| uChroma | 0 – 1 | 0,2 | 0,05 |
| uMid | 0,2 – 0,8 | 0,5 | 0,5 |
| uShadowProt | 0 – 1 | 0,3 | 0,3 |
| uHighProt | 0 – 1 | 0 | 0,2 |
| uSensor | 0 – 1 | 0 | 0 |
| uReadFloor | 0 – 1 | 0,25 | 0,25 |
| uFlicker | 0 – 0,08 | 0 | 0,03 |
| uDrift | 0 – 0,04 | 0 | 0,01 |
| uDust | 0 – 1 | 0 | 0,3 |
| uScratch | 0 – 1 | 0 | 0,2 |
| uVignette | 0 – 0,5 | 0 | 0,2 |
| uWarm | 0 – 0,3 | 0 | 0,12 |
| uLift | 0 – 0,06 | 0 | 0,03 |
| Bildrate | 12 – 30 Hz | 24 | 24 |

Alle Standardwerte sind eigene Vorschläge, [Nicht geprüft], und müssen auf dem Gerät abgestimmt werden. Belegt sind nur die Vindral-Werte (Chroma 20 %, Mitte 50 %, Schattenschutz 30 %) und die Sapphire-Voreinstellungen.

## 7. Offen / nicht geprüft

- Messung der Kosten (ms je Bild) auf Zielgeräten, Skia vs. Impeller (Vulkan/GLES).
- Ob Signed-`int` und Schleifen in Flutter-Shadern sicher laufen (Doku schweigt).
- Präzision (`highp`/`mediump`) unter Impeller; Einheit von `FlutterFragCoord`.
- Gütevergleich Hoskins-Hash gegen PCG im Korn (sichtbare Muster?).
- Resolve „Film Grain“-OFX und Dehancer-Grain-Regler: Seiten nicht gefunden/gelesen.
- Typische Zahlenwerte für Staub-, Kratzer- und Wackelhäufigkeit echter Projektion: keine Quelle gefunden.
- WCAG 2.3.1 (Blitzschwelle) vor Release lesen.
- Blendmodus-Variante ohne Backdrop (Overlay/SoftLight) in Flutter.
- Foi et al. 2008 Poisson-Gauß-Volltext.
