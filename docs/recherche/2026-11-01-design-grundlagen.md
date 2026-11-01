# Design-Grundlagen für fasan_ui (01.11.2026)

Kurzfassung zuerst; Details darunter. Ungeprüftes ist als „nicht geprüft“ markiert.

## Kurzfassung

| Thema | Folgerung für fasan_ui | Beleg |
| --- | --- | --- |
| Rams' 10 Prinzipien | Standardstil „Ruhe“: wenig Elemente, klare Ordnung, ehrliche Zustände (nichts zeigen, was nicht geht) | Vitsœ [1] |
| Apple HIG / Liquid Glass | Glas nur für die Bedien-Ebene (Leisten, Blätter), nie für Inhalte. Glas reagiert auf Berührung mit Licht. Ersatz ohne Transparenz und bei hohem Kontrast muss sauber aussehen | Apple [2][3] |
| Ästhetik und Bedienbarkeit | Schönheit verändert die empfundene Bedienbarkeit messbar; deshalb lohnt der Aufwand, aber er ersetzt keine Bedienregel | Tractinsky et al. 2000 [4] |
| Bewegung | Dauern aus `GRUNDSAETZE.md` (150/220/320 ms) bleiben; dazu Federn für Gesten. „Animationen entfernen“ → 0 ms | GRUNDSAETZE, Flutter `MediaQuery.disableAnimationsOf` [6] |
| Filmeffekte als Shader | Fragment-Shader (GLSL `.frag`) im Paket, `FragmentProgram.fromAsset`. Effekte, die den Inhalt brauchen (Glow, Halation, Bleeding), nur mit `ImageFilter.shader` und nur unter Impeller; sonst Ersatz ohne Shader | Flutter-Doku [5], lokale SDK-Quelle 3.47.7 |
| Akku | Stufen aus Akkustand, Energiesparmodus und Wärmestatus. Bei „Sparen“: keine laufenden Effekte, keine Dauer-Animationen, dunkles Theme anbieten | Android-Referenz [7][8], Apple WWDC22 [9] |

## 1. Rams

Die zehn Prinzipien laut Vitsœ: innovativ, nützlich, ästhetisch, verständlich, unaufdringlich, ehrlich, langlebig,
konsequent bis ins Detail, umweltfreundlich, so wenig Design wie möglich [1].
Umsetzung: Stil „Braun“ ist die strengste Form (Raster, Grautöne, ein Signalorange). „Ehrlich“ und
„umweltfreundlich“ stützen die Akku-Stufen: Effekte sind Zugabe, nie Pflicht.

## 2. Apple HIG 2026 (Liquid Glass)

- Liquid Glass ist ein Material, das Licht bricht, Inhalte durchscheinen lässt und sich an hell/dunkel anpasst [2][3].
- Es bildet eine eigene Ebene für Bedienung und Navigation über dem Inhalt [3].
- Bewegung und Aussehen sind zusammen entworfen; auf Berührung „leuchtet“ das Glas kurz auf [3].
- Systemoptionen „Transparenz reduzieren“ und „Bewegung reduzieren“ müssen greifen (laut Sekundärquellen; Apple-HIG-Seite selbst nicht abgerufen, nicht geprüft).
- Name „Liquid Glass“ gehört Apple; Fasan nennt es „Glas“ (Beschluss 11.10.).

Umsetzung: `FasanGlass` = Weichzeichner (`BackdropFilter` mit `ImageFilter.blur`), leichte Tönung, feine helle
Kante, kurzer Lichtpunkt beim Tippen. Ohne Effekte (Akku/Kontrast) wird es eine deckende Fläche.

## 3. Ästhetik und Bewegung in Studien

- Tractinsky, Katz & Ikar 2000: Die Gestaltung beeinflusste nach der Nutzung die empfundene Schönheit **und**
  Bedienbarkeit, die tatsächliche Bedienbarkeit dagegen nicht [4]. Das ist ein Wahrnehmungseffekt; er rechtfertigt
  Sorgfalt, aber keine Abstriche bei Zielgrößen oder Klarheit.
- Bewegung erklärt Veränderung (Chang & Ungar 1993, Heer & Robertson 2007; in `GRUNDSAETZE.md`).
- Federn statt fester Kurven für Gesten: Bewegung übernimmt die Geschwindigkeit des Fingers. Begründung aus Apple
  WWDC 2018 „Designing Fluid Interfaces“ (nicht erneut abgerufen, nicht geprüft). Flutter bietet `SpringSimulation`
  und `SpringDescription` (lokale SDK-Quelle).

## 4. Filmeffekte als Flutter-Fragment-Shader

Aus der Flutter-Doku [5] und der SDK-Quelle `dart:ui` (3.47.7):

- Shader stehen in `pubspec.yaml` unter `flutter: shaders:`; aus Paketen heißen sie `packages/<paket>/<pfad>`.
- Laden: `FragmentProgram.fromAsset`, dann `fragmentShader()`; Werte mit `setFloat` (Index ohne Sampler),
  Bilder mit `setImageSampler` (Index ab 0).
- Nicht unterstützt: UBOs/SSBOs; einziger Sampler-Typ ist `sampler2D`; nur die Zwei-Argument-Form von `texture` [5].
- `ImageFilter.shader` geht nur mit Impeller; abfragbar mit `ImageFilter.isShaderFilterSupported`. Die Engine setzt
  Sampler 0 = Eingabebild und Float 0/1 = Breite/Höhe. Unter OpenGLES ist y gespiegelt [5].
- Mit `BackdropFilter` immer `ClipRect`, sonst gilt der Filter für den ganzen Bildschirm [5].

Aufteilung in fasan_ui:

| Effekt | Weg | Kosten |
| --- | --- | --- |
| Grain | eigener Shader über `Paint.shader` (kein Eingabebild) | gering; animiert nur ohne Sparstufe |
| Bildstandwackeln | Transformation (Verschiebung < 1 px), kein Shader | sehr gering |
| Glow, Halation, Light Bleeding | ein Shader mit `ImageFilter.shader` (liest Inhalt, hebt helle Stellen, rötlicher Saum bei Halation) | mittel bis hoch; nur Impeller, nur ohne Sparstufe |
| Vignette, Overlay-Linien | `CustomPainter` | gering |

## 5. Akku-Sparwege (Android)

Geprüft in `android.jar` (API 36) und der Android-Referenz [7][8]:

- `PowerManager.isPowerSaveMode()` und Broadcast `ACTION_POWER_SAVE_MODE_CHANGED` [7].
- `PowerManager.getCurrentThermalStatus()` (`THERMAL_STATUS_NONE` … `SHUTDOWN`) und `addThermalStatusListener` [8].
- `BatteryManager.BATTERY_PROPERTY_CAPACITY` für den Akkustand.
- `Surface.setFrameRate(...)` erlaubt eine niedrigere Bildrate (in android.jar vorhanden; in Flutter ohne eigenen
  Engine-Eingriff nicht direkt nutzbar, nicht geprüft).
- `Settings.Global.ANIMATOR_DURATION_SCALE` = Systemoption „Animationen entfernen“; Flutter liefert sie als
  `MediaQuery.disableAnimationsOf` [6].
- Dunkle Oberflächen sparen auf OLED-Bildschirmen viel Strom; Apple nennt bis zu 70 % Displayleistung [9].
  Für Android hier nicht gemessen (nicht geprüft).

Stufen in fasan_ui:

| Stufe | Wann | Wirkung |
| --- | --- | --- |
| Voll | Standard | alle gewählten Effekte, subtil |
| Sparen | Akku ≤ 20 %, Energiesparmodus oder Wärme ≥ `MODERATE` | keine laufenden Effekte; Glas ohne Weichzeichner; Grain still |
| Akku maximal | vom Nutzer gewählt | Sparen + dunkles Theme + keine Shader + kürzeste Animationen |

Der Nutzer kann jede Automatik abschalten (Beschluss 01.11.).

## Quellen

1. Vitsœ, „Good design“: https://vitsoe.com/us/about/good-design
2. Apple Developer, Liquid Glass (Technology Overview): https://developer.apple.com/documentation/technologyoverviews/liquid-glass
3. Apple WWDC25 „Meet Liquid Glass“ (Sitzung 219): https://developer.apple.com/videos/play/wwdc2025/219/
4. Tractinsky, Katz, Ikar (2000), What is beautiful is usable, Interacting with Computers 13(2): https://doi.org/10.1016/S0953-5438(00)00031-X
5. Flutter, „Writing and using fragment shaders“: https://docs.flutter.dev/ui/design/graphics/fragment-shaders
6. Flutter API, MediaQuery: https://api.flutter.dev/flutter/widgets/MediaQuery-class.html
7. Android, PowerManager: https://developer.android.com/reference/android/os/PowerManager
8. Android, PowerManager (Wärmestatus): https://developer.android.com/reference/android/os/PowerManager#getCurrentThermalStatus()
9. Apple WWDC22 „Power down: Improve battery consumption“: https://developer.apple.com/videos/play/wwdc2022/10083
