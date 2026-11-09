# Echtes Glas in Flutter 3.47 (Brechung, Reflexe, Frost, Berührung) – Recherche 02.11.2026

Nur lesend recherchiert. Nichts gesendet, nichts geschrieben außer dieser Datei.
Flutter-Quelltext = lokales SDK `/home/claude/sdk/flutter`, Version 3.47.7 (Commit `abaf9c52`, 08.10.2026).
Quellenkürzel: [SDK] lokaler Quelltext · [Issue #n] GitHub flutter/flutter · [pub] pub.dev-API/README · [Doku] docs.flutter.dev.
„nicht geprüft“ = nicht selbst gelesen oder nicht gemessen.

## Kurzfassung

- Der Hintergrund wird nur unter Impeller lesbar: `BackdropFilter` + `ImageFilter.shader`. Unter Skia wirft das einen Fehler. [SDK painting.dart ~4461–4464]
- **Ursache „Emulator kopfüber“ (sehr wahrscheinlich):** Seit Flutter 3.46/3.47 ist die GLES-Textur nicht mehr gespiegelt. `bloom.frag` spiegelte unter `IMPELLER_TARGET_OPENGLES` trotzdem. [Doku Breaking Change; SDK render_pass_gles.cc; Commit 0a2890a]
- Die Flutter-Doku (docs.flutter.dev und Dart-Kommentar im SDK 3.47.7) nennt den Spiegel noch. Das ist für 3.47 veraltet. Maßgeblich: Engine-Quelltext und Breaking-Change-Seite.
- **„Dunkler Kasten auf dem S23“:** `grain.frag` hatte mediump-Überlauf (euer Commit 792bb36). `bloom.frag` hatte ebenfalls `mediump`. Ob der Kasten je vom Bloom kam, ist nicht belegt.
- Die Eingabetextur des Filters wird mit **Nearest** gelesen (kein Filter). Abhilfe im Shader; API `filterQuality` kommt erst nach 3.47.7. [Issue #188365, PR #188544; SDK ohne Parameter]
- Koordinaten: `uSize` = Größe der Filtereingabe. In Scroll-/Clip-Fällen weicht sie ab. Offen: [Issue #185175], PR #193275.
- `BackdropGroup`/`BackdropKey`: seit Stable 3.29.0. Teilt eine Hintergrundkopie. Kosteneinheit ist die Kopie, nicht das Widget. [SDK; Commit c4c545215ad]
- `ImageFilter.compose(shader, blur)` hat in 3.41.3 bis 3.47.7 einen Leistungsfehler bei Clips weit von links oben. [Issue #194832, offen]
- Pakete: `liquid_glass_renderer` 1.0.0-dev.2 (Apache-2.0) braucht Flutter GPU (Vorschau, Schalter nötig). `liquid_glass_widgets` und `liquid_glass_easy` (MIT) nutzen Fragment-Shader. Keine GPL gefunden.
- Empfehlung: **eigener Shader** (Rand-SDF + Brechung + Glanz), Stufen S0–S4 mit Rückfall bis „ohne Hintergrundlesen“. Pakete als Referenz, nicht als Pflicht.
- Pflicht vor Einbau: Test auf Emulator (GLES) **und** S23 (Vulkan) **und** S23 mit erzwungenem `opengles`, mit asymmetrischem Testbild.

## 1. APIs, die den Hintergrund lesen

| API | Aussage | Quelle |
|---|---|---|
| `BackdropFilter(filter: ImageFilter.shader(fs))` | Eigener Shader bekommt das bisher Gemalte als Eingabe. Nur Impeller. | [Doku fragment-shaders „ImageFilter API“]; [SDK painting.dart] |
| `ImageFilter.isShaderFilterSupported` | Prüft zur Laufzeit. Ohne Impeller wirft `ImageFilter.shader` `UnsupportedError`. | [SDK painting.dart ~4461–4487] |
| Pflichtform des Shaders | Erstes Uniform `vec2` (Engine setzt Größe der Textur). Mindestens ein `sampler2D`, der erste ist die Eingabe. Beide nicht aus Dart setzen. | [SDK painting.dart ~4420–4430, 4465–4479]; [Doku] |
| Float-Index | `setFloat` zählt Sampler nicht mit. Reihenfolge der Uniforms = Index. | [Doku „Uniforms“] |
| `ClipRect`/`ClipRRect` | Ohne Clip wirkt der Filter auf den ganzen Bildschirm. Clip begrenzt die Fläche. | [SDK basic.dart BackdropFilter-Doku]; [Doku] |
| `ImageFilter.compose(outer, inner)` | Hintereinander: `outer(inner(quelle))`. Shader+Blur möglich, aber siehe Fehler unten. | [SDK painting.dart ~4405] |
| `BackdropKey` / `BackdropGroup` / `BackdropFilter.grouped` | Mehrere Filter teilen eine Hintergrundkopie. Überlappende Filter dürfen **nicht** denselben Schlüssel teilen. | [SDK basic.dart ~466–520] |
| `BackdropFilter.filterConfig` / `ImageFilterConfig` | Neuere Konfiguration (Commit 0015d2b6bfa, 30.12.2025, Stable 3.41.0). Für Glas nicht nötig. | [SDK git log] |
| Fragment-Shader als `Paint.shader` | Liest **nicht** den Hintergrund, nur eigene Sampler (Bild aus `Picture.toImageSync`). Läuft auch unter Skia. | [Doku „Canvas API“, „Samplers“] |

Versionen (aus `git tag --contains` im SDK, nur Stable-Tags):
- `BackdropKey`/`BackdropGroup`: Commit c4c545215ad vom 25.10.2024, erste Stable 3.29.0.
- `ImageFilter.shader`: Commit bc593759780 (Engine-PR 53490) vom 08.11.2024, erste Stable 3.29.0.
- `isShaderFilterSupported`: vorhanden im SDK 3.47.7. Der Dart-Doku-Satz „Impeller only“ wurde im PR #179387 geschärft.

Grenzen des Shaders: kein UBO/SSBO, nur `sampler2D`, nur 2-Argument-`texture`, keine eigenen Varyings, keine Booleans/unsigned. [Doku „Authoring shaders“]
Standard-Kachelmodus des Samplers ist `clamp`; anders nur im Shader nachbauen. [Doku „Samplers“]
Ausgabe muss **premultiplied alpha** sein. [Doku „Colors“]
`FlutterFragCoord()` statt `gl_FragCoord` (Impeller kann `gl_FragCoord` nicht umschreiben). [Doku „Current position“]

## 2. Der Fehler: kopfüber (Emulator) und dunkler Kasten (S23)

### 2.1 Spiegelung (Y-Achse) – Befund

Belege, in Reihenfolge:
1. **Altes Verhalten (≤ 3.44):** GLES speicherte Render-Texturen unten-oben. Shader mussten unter `IMPELLER_TARGET_OPENGLES` `uv.y = 1.0 - uv.y` setzen. Dokumentiert durch [Issue #169761] (30.05.2025, „document reverse-y requirement for ImageFilter.shader. Otherwise things are upside down.“).
2. **Änderung:** [Issue #186554] / [PR #186556] „Retire Y-coord-scale plumbing by flipping GLES at the vertex stage“, gemerged 26.05.2026. Seit 3.46.0-0.1.pre; stabil in 3.47. [Doku Breaking Change „OpenGL ES render-to-texture orientation“, docs.flutter.cn]
3. **Folge laut Breaking-Change-Seite:** „Shaders that flipped the Y coordinate on OpenGL ES to match other backends will now render upside down.“
4. **Engine-Quelltext 3.47.7 bestätigt:** Offscreen-FBO-Pässe spiegeln im Vertex-Shader (`flip_y = !is_wrapped_fbo`). [SDK `impeller/renderer/backend/gles/render_pass_gles.cc` Zeilen 356–368]
5. **Abhilfe-Makro:** `IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED` wird auf GLES definiert, „to target Flutter <= 3.44 before the OpenGLES flip was removed“. [SDK `impeller/compiler/compiler.cc` ~493–495]; [PR #187316 „Adds macro for fragment shaders to support flutter <= 3.44“, gemerged 03.06.2026]
6. **Flutter selbst entfernte seinen Spiegel** im Stretch-Effekt: [PR #187247]. Der Stretch-Shader im SDK 3.47.7 hat keinen `IMPELLER_TARGET_OPENGLES`-Zweig. [SDK `stretch_effect.frag`]

Euer Fall: `bloom.frag` (Commit 0a2890a) enthielt
`#ifdef IMPELLER_TARGET_OPENGLES  uv.y = 1.0 - uv.y;`. Das ist unter 3.47 falsch auf GLES. Passt zu „Emulator kopfüber“ (Emulator = GLES). Vulkan (S23) hat den Zweig nicht, also dort richtig herum. (Schluss aus 1–6; Bloom wurde nicht erneut gebaut.)

Richtig für **nur 3.47+** (fasan_ui verlangt `flutter >=3.47.0`):
```glsl
// kein Spiegel. Eingabe ist auf allen Backends oben-links.
vec2 uv = FlutterFragCoord().xy / uSize;
vec4 c = texture(uBackdrop, uv);
```
Für Shader, die auch ≤ 3.44 sollen:
```glsl
#ifndef IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;   // nur alte Flutter-Versionen
#endif
#endif
```
Quelle: [Doku Breaking Change, „Shaders supporting older releases too“].

Widerspruch: Das Beispiel in docs.flutter.dev (Fragment shaders) und der Doku-Kommentar in `painting.dart` ~4432–4458 zeigen noch den alten Spiegel. Für 3.47 nicht mehr anwenden. (Doku-Fehler; wir melden nichts, weil nichts geschrieben werden darf.)

`FlutterFragCoord()` ist vom Spiegel nicht betroffen: Es kommt aus `_fragCoord = position` im Vertex-Shader. [SDK `entity/shaders/runtime_effect.vert`, `compiler/shader_lib/flutter/runtime_effect.glsl`]
Nur das **Lesen der Engine-Textur** hängt an der Orientierung.

### 2.2 Dunkler Kasten auf dem S23 – Stand

- Belegt: `grain.frag` mit `precision mediump` lief ab Zelle ~148 über (GLSL ES 3.00 §4.5.2: mediump nur ±2^14). Folge: Korn nur oben links, Rest dunkel/leer. [Commit 792bb36]
- Der Bloom-Shader hatte ebenfalls `precision mediump float;` und rechnet mit `FlutterFragCoord()/uSize`. [Commit 0a2890a]
- Der Commit 6f0bf12 schrieb den dunklen Kasten dem Bloom-Test zu. Der Kasten der Version 0.1.2–0.1.8 kam laut 792bb36 vom **Korn**. Möglich: Der Bloom-Befund war nie sauber getrennt. Nicht belegt, nur Schluss.
- Fremde Bestätigung für Präzision: `liquid_glass_renderer` setzt `precision highp float;` und schreibt „mediump turns the coordinate subtraction into visible shimmer on large layers“. [pub, `liquid_glass_final_render_core.glsl` Z. 7–10]
- Weitere Geräte-Fehler als Beispiel: Mali-Vulkan (Pixel 8/9) lieferte bei einem Ternary in der SDF-Dekodierung eine halb gedeckte Fläche über das ganze Rechteck. Abhilfe `step()/mix()`. [pub, CHANGELOG 1.0.0-dev.2, Fehler #246 des Pakets]
  Daraus: SDF-Code ohne Ternary und ohne frühe `return`s schreiben (Vorsicht auf Mali/Vulkan).

Regel für unsere Shader: `precision highp float;`, Eingaben klein halten, kein Ternary in der Kantenberechnung, Testbild.

### 2.3 Weitere belegte Stolpersteine bei `ImageFilter.shader` unter 3.47

| Problem | Beleg | Stand |
|---|---|---|
| UV-Raum bei Clip: Koordinaten lagen im Raum der ClipRect-Ebene statt des Bildschirms | [Issue #178798] (beta 3.39, 2025-11), geschlossen 27.11.2025 | behoben; zeigt: UV nie als Bildschirmkoordinate annehmen |
| Mit zusammengesetztem Blur falsche UVs | [Issue #181660], geschlossen 07.02.2026, Fix [PR #181743] (+1 px/Puffer um neu gerasterte Eingabe) | behoben, brachte aber #194832 |
| Eingabe ist bei Clip im Scroll nur der sichtbare Teil; Effekt wird gestreckt | [Issue #185175], offen; Fix-Entwurf [PR #193275] „unclippedInput“ (offen) | **offen** |
| `compose`: Sampling außerhalb des inneren Filters unterscheidet sich je Backend (Vulkan/Metal „wrong“, GLES erwartet) | [Issue #177795], offen | **offen** → im Shader UV spiegeln/klemmen |
| `compose` nur mit Shader als `outer` | [Issue #170973] (geschlossen 27.10.2025) | behoben |
| Eingabe-Sampler ist Nearest, Treppen bei verzogenen UVs | [Issue #188365]; Fix [PR #188544] gemerged 30.07.2026 | **nicht in 3.47.7** (SDK `ImageFilter.shader(FragmentShader)` ohne Parameter geprüft) |
| Sampler liest außerhalb der Textur: GLES schwarz (Decal) | [pub, `liquid_glass_final_render_core.glsl` `mirrorBackgroundUV`] | im Shader klemmen/spiegeln |
| Zwei Shader-Backdrops übereinander: auf echtem iPhone (Metal) alter Frame als Eingabe | [Issue #187820], geschlossen 15.07.2026 | nur iOS gemeldet; Android nicht geprüft |
| `Opacity` um `ImageFiltered` mit Shader wirkt nicht | [Issue #171378], offen (nur Titel gelesen) | meiden |
| Mehrere ImageFilter mischen nicht | [Issue #177133], offen (nur Titel gelesen) | – |

Die Schritte „Quelle prüfen“ der Issues: Texte von #178798, #181660, #185175, #177795, #188365, #187820, #194832, #193275 gelesen; #171378, #177133, #186554 (Text), #187316, #187247 nur Titel/Kurztext.

## 3. Pakete auf pub.dev (Stand 02.11.2026)

Alle Zahlen aus `pub.dev/api/packages/<name>` und `/score`. Lizenz = erkannte Lizenz-Marke + bei Nr. 1 LICENSE-Kopf gelesen.
MPL-2.0-App darf permissive Pakete (MIT, Apache-2.0, BSD-3) einbinden (rechtlich nicht geprüft; keine GPL gefunden).

| Paket | Version / Datum | Lizenz | Technik | Grenzen | Pflege |
|---|---|---|---|---|---|
| `liquid_glass_renderer` | 1.0.0-dev.2 · 27.10.2026 | Apache-2.0 (LICENSE gelesen); Abhängigkeiten BSD-3/MIT | Neu geschrieben auf **Flutter GPU**: Matte (Rand-Abstand, Richtung) in Viertelauflösung, Endpass mit Brechung, Frost, Glint, Kontur, Verschmelzen. Quarter-Circle-Abfall der Verschiebung. | Flutter ≥ 3.47, SDK `>=3.13.0 <3.14.0`. Volles Glas nur mit Impeller + **Flutter GPU (Vorschau, Schalter `io.flutter.embedding.android.EnableFlutterGPU` nötig)**. Sonst `FakeGlass` (nur Blur, ohne Brechung). Höchstens 16 Formen je Ebene. „Experimental“. | 34 Versionen, 903 Likes, Leistungs-Audit mit Pixel 10 im Repo |
| `liquid_glass_widgets` | 1.16.1 · 30.10.2026 | MIT | Fragment-Shader; auf Impeller Zwei-Pass-Gauß + Brechung; Skia/Web nur leichter Shader. Chromatische Aberration. Auf GLES 8 statt 16 Formen. | Flutter ≥ 3.41. „Galaxy S23/S24/S25 … Vulkan voll“ ist Eigenaussage des README, nicht von uns geprüft. Adaptive Qualität „experimentell“. | 188 Versionen, 362 Likes |
| `liquid_glass_easy` | 5.2.0 · 02.11.2026 | MIT | Linse brechend; Impeller liest Live-Hintergrund; `LiquidGlassBatch` mit `ImageFilter.compose` + gemeinsamem Schlüssel (laut Autor in #194832). Lite-Modus ohne Shader. | Skia braucht eigenen `LiquidGlassView`. Von #194832 betroffen (7–8 ms → > 20 ms). | 26 Versionen, 280 Likes |
| `glass_forge` | 0.1.1 · 30.09.2026 | MIT | Flutter GPU; Stufen full/…/flat; ein `BackdropFilter` je Material | Flutter ≥ 3.47; 2 Versionen, 0 Likes | jung |
| `liquiglass` | 1.0.0 · 20.10.2026 | Apache-2.0 | `BackdropFilterLayer` + `ImageFilter.shader`; nur Android; geprüft laut README auf Pixel 7 (Vulkan) und Android-17-Emulator (GLES) | Eine Version, 0 Likes | jung |
| `retcore_liquid_glass`, `liquid_glass_flutter`, `flutter_liquid_glass` | 2025/2026 | MIT | – (Technik nicht geprüft) | kaum gepflegt (0–4 Likes, 2 Versionen) | nicht verwenden |

Quellen: [pub API], README/CHANGELOG/Shader von `whynotmake-it/flutter_liquid_glass` (raw.githubusercontent.com), READMEs der anderen Repos.
Nicht geprüft: Netzwerkzugriff der Pakete (Fasan-Regel „keine fremden SDKs mit Netzwerkzugriff“); Größe; ob die Shader auf dem S23 laufen.

Bewertung:
- `liquid_glass_renderer` ist die beste **Referenz** (Messdaten, Quelltext offen, Apache-2.0). Als Abhängigkeit riskant, weil Flutter GPU eine Vorschau ist und ein Manifest-Schalter nötig wird.
- `liquid_glass_widgets` ist der nächste Kandidat als Abhängigkeit, wenn wir keinen Eigenbau wollen (MIT, viele Versionen). Nicht auf unseren Geräten geprüft.
- Eigenbau bleibt nötig für: Fasan-Profile, „Animationen entfernen“, „Akku maximal“, Quirk-Tabelle (Fasan-Regel „viele Geräte“).

## 4. Technik der Brechung (vereinfacht)

Alle Formeln sind Ableitung für einen Fasan-Shader, **kein** Apple-Code. Parameter sind zu justieren. Gegen Apple nicht gemessen.

1. **Form als Signed Distance Field (SDF).** Abgerundetes Rechteck, 2D, mit `p` relativ zur Mitte, `b` = halbe Größe, `r` = Radius:
   `q = abs(p) - b + r;  d = length(max(q,0.0)) + min(max(q.x,q.y),0.0) - r;`
   Quelle: Inigo Quilez, „Round Box – exact“ (3D-Form; 2D folgt durch Weglassen von z) [iquilezles.org/articles/distfunctions].
   `d < 0` innen. Abstand zum Rand = `-d`.
2. **Normale am Rand.** Gradient der SDF, entweder analytisch oder durch vier Auswertungen (`d(p+ex)-d(p-ex)`, `d(p+ey)-d(p-ey)`) und `normalize`. Zeigt nach außen. (Standardverfahren; Quelle für das Verfahren selbst nicht geprüft.)
3. **Fase (Bevel).** Nur ein Rand der Breite `bevel` bricht; die Fläche zeigt den Hintergrund unverschoben. Das tut auch `liquid_glass_renderer`: „Only the bevel refracts; the face shows the backdrop undisplaced.“ Verschiebung fällt „as a quarter circle“ ab. [pub README „Refraction“]
   Mit `t = clamp(abstand/bevel, 0, 1)` (0 am Rand, 1 innen) ist die Höhe eines Viertelkreises `h(t) = sqrt(1 - (1-t)^2)`. Die Normale der Fase ist dann `N = normalize(vec3(n_aussen * (1-t), h))` (Geometrie eines Kreises, eigene Herleitung).
4. **Verschiebung nach Snell, vereinfacht.** `refract(I, N, eta)` mit `I = (0,0,-1)` (Blick senkrecht auf die Fläche), `eta = 1/ior` (Luft→Glas, `ior ≈ 1,5`). Definition: `k = 1 - eta²(1 - dot(N,I)²)`, `R = eta·I - (eta·dot(N,I) + sqrt(k))·N`, bei `k < 0` Nullvektor. [GLSL-`refract`, thebookofshaders-Glossar]
   Luft→Glas gibt `k > 0` immer, also keine Totalreflexion.
   Verschiebung in Pixeln: `offset = R.xy / (-R.z) * dicke`. `R.xy` zeigt nach innen, also wird der Hintergrund von weiter innen gelesen (wie „samples inside“ beim Paket).
   Einfachere Ersatzform ohne `refract`: `offset = -n_aussen * stärke * sqrt(1 - t*t)`.
5. **Dicke.** `dicke` skaliert die Verschiebung. Größere Elemente = dickeres Material = mehr Verschiebung und tieferer Schatten (Apple: WWDC25 Session 219, laut eigener Notiz in `2026-11-02-glas-neigung-bewegung.md`).
6. **Chromatische Aberration.** Rot, Grün, Blau mit leicht unterschiedlicher Verschiebung lesen (3 Texturzugriffe statt 1). Paket: Rot `1 + d/2`, Blau `1 - d/2`; Standard 0, „cheapest setting“. [pub README]
7. **Glanzlicht (Specular) am Rand.** Helligkeit ~ `pow(1 - h, k) * max(dot(n_aussen, L), 0)` für Lichtrichtung `L`; zusätzlich schwächer gegenüber. Lichtrichtung aus Neigung (siehe Glas-Notiz). Gegenseite und Gewichte sind Gestaltungsentscheid.
8. **Fresnel.** Schlick: `F = F0 + (1 - F0)·(1 - cosθ)^5`, `F0 ≈ 0,04` für Glas; am streifenden Winkel gegen 1. [Concept: Fresnel Effect, code-note-gamma.vercel.app]
   Hier `cosθ = h(t)`: Rand = streifend = mehr Spiegelung.
9. **Unschärfe + Brechung.** Zwei Wege:
   a) `ImageFilter.compose(outer: shader, inner: blur)`. Paket `liquid_glass_renderer` nutzt in FakeGlass „compose(blur, shader)“. Aber: [Issue #194832] (Leistung), [Issue #177795] (Sampling-Unterschiede).
   b) Zwei Schichten: erst `BackdropFilter(blur)` + Tönung, darüber `BackdropFilter(ImageFilter.shader)` nur für Rand. Zweiter Filter liest den Blur mit (Reihenfolge der Malerei). Auf Android nicht geprüft; iOS-Fehler [Issue #187820].
   c) Blur im Shader (mehrere Taps). Teuer; Paket nutzt „native two-pass Gaussian blur“ (`liquid_glass_widgets`).
10. **Verschmelzen (Metaball).** Mehrere Formen: SDF-Werte mit glatter Vereinigung kombinieren:
    `h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);  d = mix(d2, d1, h) - k*h*(1.0-h);`
    `k` = Größe des Übergangs in Abstandseinheiten. [iquilezles.org `opSmoothUnion`]
    Paket: `LiquidGlassBlendGroup`, Standard `blend: 20` px, höchstens 16 Formen je Ebene; „Moving one shape in a group re-renders the whole group's geometry“. [pub README]
    Außerhalb der Vereinigung Ausgabe mit Alpha 0 (premultiplied). Dass der Hintergrund dann unverändert bleibt, ist hier nicht geprüft.

Berührung: Leuchten von innen unter dem Finger, gelartiges Federn: siehe `2026-11-02-glas-neigung-bewegung.md`. Technisch Uniform `uPress` (0–1) und `uTouch` (Fingerposition in Texturraum), Verschiebung/Glow in der Nähe des Fingers. Nicht gebaut.

## 5. Leistung auf Mittelklasse-Handys

Belege, keine eigenen Messungen:
- Eine Hintergrundkopie je unabhängigem `BackdropFilter`; teilen mit gleichem `BackdropKey` macht „only one backdrop blur“. [SDK basic.dart ~505–520]
- „The unit of cost is the backdrop copy, not the glass widget.“ Rat: Geschwister in eine Ebene, kleine Ebenen, wenige Schatten, Blend-Gruppen nicht jedes Bild bewegen, `FakeGlass` ist **nicht** billiger. Für Strom sparen: „don't sample the backdrop“, undurchsichtige Fläche. [pub README „Performance“]
- Leseauszüge sind **vollbild**, egal wie klein die Form: „Readbacks are full-screen regardless of shape size.“ Eigene Lupe mit eigenem Backdrop: +120 bis 145 mW GPU gegenüber Mitnutzen der Gruppe (Pixel 10). [pub, `performance-audit.md`, 15.09.2026]
- Halbe Matte-Auflösung wurde verworfen (Rundungsartefakte), Viertelauflösung 4×4 genommen. [pub, `performance-audit.md`; CHANGELOG #252]
- Viele Formen/Elemente: Fehler [Issue #194832] (Flutter 3.41.0–3.41.2 gut, 3.41.3–3.47.7 betroffen): 7–8 ms → über 20 ms bei `compose(shader, blur)` mit geteiltem Schlüssel; je weiter der Clip von links oben, desto größer die neu gerasterte Textur (Ursache nach Bericht: [PR #181743]). **Offen.**
- Impeller auf alten GPUs: [Issue #187009] (Adreno 506: 28 statt 54 FPS, offen), [Issue #192147] (GLES setzt Zustand je Draw neu, 2–3× langsamer als Skia-GL auf Adreno 610, geschlossen 02.09.2026; ob der Fix in 3.47.7 steckt: nicht geprüft), [Issue #193148] (3.47.1: Vulkan-Sperre auf Mali-G52 wegen Hersteller-SDK, GLES-Rückfall +40 bis 90 MB Grafikspeicher, offen).
- Eigenes Shader-Rat von Flutter: auf älteren Geräten messen, `highp`/`mediump` abwägen (mediump ist schneller, aber siehe Überlauf), Verzweigungen nicht stur wegglätten. [SDK `docs/engine/impeller/docs/shader_optimization.md`]

Empfehlungen für Fasan (abgeleitet):
1. **Eine** gemeinsame Hintergrundkopie je Bildschirm (`BackdropGroup` + `BackdropFilter.grouped`), nicht je Knopf.
2. Knöpfe, die sich berühren oder verschmelzen, in **einem** Shader-Filter über die Gruppenfläche (Abschnitt 4, Nr. 10), nicht als viele Filter.
3. Nur dort brechen, wo es sich lohnt: Fase schmal (z. B. 12–20 dp), Fläche innen ohne Verschiebung (ein Zugriff).
4. Keine Dauer-Animation der Gruppen-Geometrie. Bewegung nur bei Berührung, dann zurück in Ruhe.
5. Kein `compose(shader, blur)` bis #194832 geklärt ist; Frost über zweite Schicht oder ohne Blur (nur Tönung).
6. Profile-Build auf Mittelklasse-Gerät (nicht S23) messen. **Noch keine Messung vorhanden.**
7. Stufen an die vorhandenen Akku-Stufen koppeln (Voll / Sparsam / Maximal).

## 6. Umsetzungsvorschlag mit Rückfallstufen

Annahmen: `fasan_ui` verlangt `flutter >=3.47.0`; Android Impeller (Vulkan oder GLES). Kamera-Sucher wird nie verdeckt (CLAUDE.md Kamera): Glas nur auf Bedienflächen, nie über dem Sucher als Linse.
Ob `BackdropFilter` über einem Kamera-`Texture`/PlatformView den Hintergrund richtig liest: **nicht geprüft**. Vor Einbau testen.

### Stufen

| Stufe | Was | Bedingung | Kosten |
|---|---|---|---|
| **S0 Brechung** | `BackdropFilter(ImageFilter.shader)` mit Fase-Brechung, Glanz, Fresnel, optional Dispersion | `ImageFilter.isShaderFilterSupported` und Profil „Voll“ und Gerät besteht Selbsttest | Hintergrundkopie + Shader über Fläche |
| **S1 Brechung + Frost in Shader** | Wie S0, aber Frost durch zweite Schicht `BackdropFilter(blur)` darunter (nicht `compose`) | Messung zeigt Zeitbudget frei | + 1 Kopie (oder geteilt über `BackdropGroup`) |
| **S2 Falsche Brechung** | `BackdropFilter(blur)` + Tönung + **eigener Randlicht-Shader als `Paint.shader`** (CustomPainter, liest den Hintergrund nicht) | Impeller ohne Shader-Filter, Skia, Selbsttest fehlgeschlagen, Profil „Sparsam“ | 1 Kopie |
| **S3 Ohne Hintergrundlesen** | Halbdeckende Fläche + Randlicht (`Paint.shader`/Gradient) + Schatten | „Akku maximal“, „Transparenz reduzieren“, Selbsttest weiterhin fehlerhaft | keine Kopie |
| **S4 Kontrast** | Undurchsichtig, schwarz/weiß mit Rand | „Kontrast erhöhen“ | minimal |

Zusatzoption **E (eigener Grund als Textur):** Das Fasan-Hintergrundbild (Grund) selbst per `Picture.toImageSync` in ein Bild rendern und im Glas-Shader als **eigenen Sampler** (`setImageSampler`) lesen, über `Paint.shader` statt `ImageFilter.shader`. Vorteile: keine Orientierung der Engine-Textur, läuft auch unter Skia, nicht vom Clip-UV-Problem betroffen. Nachteil: bricht nur den eigenen Grund, nicht Inhalte darüber; Neuaufnahme bei bewegtem Grund. [Doku „Samplers“, „toImageSync example“]. Nicht gebaut.

### Selbsttest (S0 aktiv schalten oder nicht)

Beim ersten Start einmal ein 32×32-Testbild (asymmetrisch: heller Pfeil oben links) mit dem Shader-Filter rendern, `Picture.toImage` lesen, Pixel prüfen:
- richtig herum, nicht schwarz, nicht ganz transparent → S0 erlaubt;
- sonst Stufe merken (pro Gerät, in den Einstellungen sichtbar) und S2 nehmen.
Das ersetzt Modell-Listen (Fasan-Regel: Verhalten aus Fähigkeiten, Ausnahmen nur Quirk-Tabelle). Dass `Picture.toImage` mit `BackdropFilter` im Testbild korrekt arbeitet, ist **nicht geprüft**; Alternative: Golden-Test in CI auf GLES/Vulkan-Emulator.

### Shader-Entwurf (nicht gebaut, nicht gemessen)

```glsl
#version 460 core
precision highp float;                 // mediump: Überlauf/Zittern, siehe Abschnitt 2.2
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;                    // float 0,1: Engine setzt Größe der Eingabe (= Clipfläche, siehe 2.3)
uniform float uRadius;                 // float 2: Eckenradius in px
uniform float uBevel;                  // float 3: Breite des brechenden Rands in px
uniform float uThickness;              // float 4: "Dicke" in px
uniform float uIor;                    // float 5: ~1.5
uniform vec2  uLight;                  // float 6,7: Lichtrichtung (normiert)
uniform vec4  uTint;                   // float 8..11: premultiplied
uniform sampler2D uBackdrop;           // Sampler 0: Engine setzt Eingabe
out vec4 fragColor;

float sdRound(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;                // lokal zur Eingabe, Ursprung oben links
  vec2 p = frag - 0.5 * uSize;
  vec2 b = 0.5 * uSize;
  float d = sdRound(p, b, uRadius);                 // < 0 innen
  vec2 e = vec2(1.0, 0.0);
  vec2 n = normalize(vec2(sdRound(p + e.xy, b, uRadius) - sdRound(p - e.xy, b, uRadius),
                          sdRound(p + e.yx, b, uRadius) - sdRound(p - e.yx, b, uRadius)) + 1e-5);
  float t = clamp(-d / uBevel, 0.0, 1.0);           // 0 Rand, 1 innen
  float h = sqrt(max(1.0 - (1.0 - t) * (1.0 - t), 0.0));
  vec3 N = normalize(vec3(n * (1.0 - t), max(h, 1e-3)));
  vec3 R = refract(vec3(0.0, 0.0, -1.0), N, 1.0 / uIor);
  vec2 off = R.xy / max(-R.z, 1e-3) * uThickness;   // zeigt nach innen
  vec2 uv = (frag + off) / uSize;
  // klemmen (GLES liefert außerhalb schwarz, siehe 2.3); ganzer Rand bleibt im Bild
  uv = clamp(uv, 0.5 / uSize, 1.0 - 0.5 / uSize);
  vec4 c = texture(uBackdrop, uv);                  // KEIN Y-Spiegel in 3.47
  float spec = pow(1.0 - h, 2.0) * max(dot(n, uLight), 0.0)
             + 0.35 * pow(1.0 - h, 2.0) * max(dot(n, -uLight), 0.0);
  float fres = 0.04 + 0.96 * pow(1.0 - h, 5.0);
  vec3 rgb = c.rgb * (1.0 - uTint.a) + uTint.rgb + vec3(spec + 0.25 * fres) * c.a;
  fragColor = vec4(min(rgb, vec3(c.a)), c.a);       // premultiplied
}
```
Hinweise:
- Außenkante antialiasen übernimmt `ClipRRect(clipBehavior: Clip.antiAlias)`. Ein `ClipRRect` mit gleichem Radius wie `uRadius` ist Pflicht (Filter wirkt sonst auf Rechteck/Vollbild).
- Nearest-Sampling der Eingabe: nur im Rand (`t < 1`) nötig weich zu lesen; innen reicht ein Zugriff. 4-Tap-Bilinear nur dort ([Issue #188365] nennt 4× Kosten pro Pixel).
- Nur eine Form je Filter. Für Gruppen: Formen als Uniform-Array (Mitte, Halbgröße, Radius), `opSmoothUnion` über `d`. Obergrenze der Formen festlegen (Paket: 16; widgets auf GLES: 8).
- Uniform-Index: `setFloat` ohne Sampler; Größe (Index 0,1) nicht setzen. [Doku]

### Berührung und „schwebende Knöpfe“

- Zustand: `press` 0→1 mit Feder (kein „Animationen entfernen“ → direkt springen). Setzt `uThickness`, Glow-Radius, Skalierung 1,0→1,06 (Wert Gestaltungsvorschlag).
- Schwebend: Schatten **unter** dem Glas als eigene `Paint`-Ebene (nicht gebrochen). Das Paket zeichnet Kind-Inhalt immer **über** dem Glas, ungebrochen. [pub README Nr. 8 „Children always paint above the glass“]
- Tippfläche ≥ 60 dp (Kamera) bzw. 48 dp (Split); Glas ist nur Optik, die Fläche bleibt Widget.
- Jede Geste braucht sichtbaren Zwilling (Fasan-Regel); Glas darf Bedienbarkeit nicht ersetzen.

### Reihenfolge der Arbeit

1. Testseite mit **asymmetrischem Bild** (Pfeil, Text) hinter Glas; Shader ohne Brechung (nur `texture(uBackdrop, uv)`), auf Emulator + S23 (Vulkan) + S23 mit `ImpellerBackend=opengles`.
   Manifest-Schalter: `<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="opengles"/>` (oder `vulkan`). [SDK `impeller/README.md` ~207–211; `FlutterEngineFlags.java` ~161]
2. Danach SDF-Rand ohne Brechung, dann Brechung, dann Glanz/Fresnel, dann Dispersion. Je Schritt Bildschirmfoto.
3. Gleiche Prüfung mit Clip nicht bei (0,0) und im Scroll ([Issue #178798], [Issue #185175]).
4. Messung (Profile) mit 1, 4, 8 Glasknöpfen auf Mittelklasse-Gerät.
5. Selbsttest + Stufen S2–S4 einbauen, bevor S0 Standard wird.
6. Referenz-Vergleich mit `liquid_glass_renderer` (Quelltext lesen, nicht einbinden) für Parameter (iOS-27-Werte: `refractionHeight 20`, `refractionAmount 60` laut README).

## 7. Nicht geprüft / offen

- Wirkung auf **Kamera-Sucher** (Texture/PlatformView) unter `BackdropFilter`.
- Messwerte für Mittelklasse (nur fremde Werte: Pixel 10, Pixel 7, iPhone 15).
- Ob GLES-Emulator oder S23 genau so zeigt, wie hier abgeleitet (Y-Spiegel stimmt mit Quelltext überein; Bloom wurde nicht neu gebaut).
- Ob der Fix für [Issue #192147] in 3.47.7 steckt.
- Rechtliche Prüfung Apache-2.0/MPL-2.0 beim Einbinden; Netzwerkzugriff der Pakete.
- Genaue Apple-Werte (Profil, Lichtgewichte). Hier nur Pakete-Werte und eigene Ableitung.
- docs.flutter.dev/perf/impeller und api.flutter.dev waren nicht abrufbar (nicht freigegeben); Ersatz: lokaler SDK-Quelltext 3.47.7 und `docs.flutter.dev/ui/design/graphics/fragment-shaders.md`.
- Issues #171378, #177133 nur Titel; #187009 und #170973 nur Anfang gelesen.

## Quellenliste

- [SDK] `/home/claude/sdk/flutter` (3.47.7): `engine/src/flutter/lib/ui/painting.dart` (ImageFilter, ~4400–4490), `packages/flutter/lib/src/widgets/basic.dart` (BackdropGroup/BackdropFilter, ~466–770), `engine/src/flutter/impeller/compiler/compiler.cc` (~486–496), `…/renderer/backend/gles/render_pass_gles.cc` (~356–368, 504–507), `…/compiler/shader_lib/flutter/runtime_effect.glsl`, `…/entity/shaders/runtime_effect.vert`, `docs/engine/impeller/docs/shader_optimization.md`, `engine/src/flutter/impeller/README.md`.
- [Doku] https://docs.flutter.dev/ui/design/graphics/fragment-shaders.md · Breaking change: https://docs.flutter.cn/release/breaking-changes/opengles-render-to-texture-top-down.md
- [Issues/PRs] flutter/flutter: #169761, #170973, #171378, #177133, #177795, #178798, #181660, #181743, #185175, #186554, #186556, #187009, #187247, #187316, #187820, #188365, #188544, #192147, #193148, #193275, #194832.
- [pub] https://pub.dev/api/packages/{liquid_glass_renderer, liquid_glass_widgets, liquid_glass_easy, glass_forge, liquiglass, retcore_liquid_glass, liquid_glass_flutter, flutter_liquid_glass} · README/CHANGELOG/`liquid_glass_final_render_core.glsl`/`performance-audit.md` von https://github.com/whynotmake-it/flutter_liquid_glass (raw) · READMEs von sdegenaar/liquid_glass_widgets, AhmeedGamil/liquid_glass_easy, Arhamss/glass-forge, shayann07/liquidglass.
- [Technik] https://iquilezles.org/articles/distfunctions (Round Box, opSmoothUnion) · GLSL `refract()` (thebookofshaders-Glossar) · Schlick-Fresnel (code-note-gamma.vercel.app).
- [Projekt] fasan_ui-Commits 0a2890a (bloom.frag), 6f0bf12, 792bb36 (Korn/mediump); `2026-11-02-glas-neigung-bewegung.md`.
