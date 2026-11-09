# Glas, Neigung, filmische Bewegung – Recherche 02.11.2026

Nur lesend recherchiert. Quellen am Ende jedes Abschnitts.

## Kurzfassung

- Apple macht Glas nicht über Unschärfe sichtbar, sondern über **Licht**: Lichtkante entlang der Form,
  Linsenwirkung (Hintergrund wird an den Rändern verzogen), Schatten, der sich dem Untergrund anpasst.
  Auf einfarbiger Fläche gibt es nichts zu verzerren – dort tragen **Lichtkante + Schatten + Tönung** allein.
- Lichter wandern bei Interaktion um die Form; „in manchen Fällen“ folgen sie der Geräte-Neigung.
- Glas erscheint nicht per Ausblenden, sondern „materialisiert“: Linsenwirkung und Licht werden hochgefahren.
- Berührung: Glas leuchtet von innen auf, das Leuchten breitet sich unter dem Finger aus, die Form federt (gelartig).
- Größeres Glas = dickeres Material: tiefere Schatten, stärkere Linse, weicheres Streulicht.
- Bedienhilfen: „Transparenz reduzieren“ → milchiger; „Kontrast erhöhen“ → schwarz/weiß mit Rand;
  „Bewegung reduzieren“ → keine Elastizität, schwächere Effekte.
- Neigung in Flutter: `sensors_plus` 7.1.1 (BSD-3, keine Android-Berechtigung, Beschleunigungssensor reicht).
- Übergänge: `animations` 3.0.0 (BSD-3, Flutter-Team): Container Transform, Shared Axis, Fade Through.

## 1. Apple Liquid Glass (WWDC25 „Meet Liquid Glass“, Session 219)

- Linsenwirkung ist das Hauptmerkmal: Licht wird gebogen und gebündelt statt gestreut. [Certain, Session 219, „Dynamics“]
- Lichtquellen der Umgebung erzeugen Glanzlichter, die der Geometrie folgen; bei Interaktion wandert das Licht um die Form
  und zeichnet die Silhouette. In manchen Fällen reagieren sie auf Gerätebewegung. [Certain, „Principles“]
- Schattendeckkraft hängt vom Untergrund ab: stärker über Text, schwächer über heller einfarbiger Fläche. [Certain]
- Tönung: aus einer Farbe wird eine Tonreihe, abgebildet auf die Helligkeit darunter (wie farbiges Glas);
  nur für Hauptelemente und Hauptaktionen. [Certain]
- Größere Glasflächen: tiefere Schatten, stärkere Linse/Brechung, weicheres Streulicht. [Certain, „Adaptivity“]
- Kleine Elemente kippen zwischen hell und dunkel, große passen sich an, kippen aber nicht. [Certain]
- Materialisieren statt Ausblenden. [Certain, „Dynamics“]
- Berührung: Leuchten von innen, breitet sich unter dem Finger und auf benachbartes Glas aus; gelartige Biegsamkeit. [Certain]
- Scrollkante: Inhalt löst sich unter dem Glas sanft auf; über dunklem Inhalt leichte Abdunklung. [Certain]
- Varianten „Regular“ (anpassend) und „Clear“ (durchsichtiger, braucht Abdunklung); nie mischen. [Certain]
- Bedienhilfen wie oben. [Certain]
- Pressetext: „reacts to movement with specular highlights“. [Certain, Apple-Pressemitteilung 09.06.2025, zitiert u. a. bei MacTech]

Quellen: developer.apple.com/videos/play/wwdc2025/219 (Transkript), Apple-Newsroom 09.06.2025.

### Umsetzung für Fasan (Ableitung, kein Apple-Code)

| Apple-Merkmal | Fasan-Umsetzung (Flutter) | Kosten |
|---|---|---|
| Lichtkante | Rand-Verlauf (SweepGradient/LinearGradient), Winkel aus Neigung, 1 dp innen hell, 0,5 dp außen dunkel | gering |
| Linse | Fragment-Shader am Rand: Hintergrund 2–6 px nach innen verziehen (nur wo Inhalt dahinter ist) | mittel, erst auf S23 prüfen |
| Schatten nach Untergrund | zwei Schatten (eng + weit); Deckkraft nach Helligkeit des Hintergrunds aus dem Theme | gering |
| Tönung | Akzentfarbe mit 6–10 % über dem Glas, nur Hauptknopf | gering |
| Materialisieren | Einblenden über Rand-Licht 0→1 und Unschärfe 0→σ statt Deckkraft | gering |
| Berührung | radialer Lichtfleck an der Fingerposition, Feder auf Skalierung 0,97→1 | gering |
| Bedienhilfen | `MediaQuery.highContrast`, `disableAnimations`; eigene Einstellung „Transparenz reduzieren“ | gering |

Die Linse ist auf einfarbigem Grund unsichtbar. Darum braucht jeder Entwurf einen **Grund mit Struktur**
(animierter Verlauf, Korn, Bonfoto). Sonst trägt nur die Lichtkante. [Likely, Schluss aus Session 219]

`BackdropFilter` + `ImageFilter.blur` ist Standard und unter Impeller unterstützt. Eigene Shader als
`ImageFilter.shader` hatten auf dem Emulator (GLES) das Bild kopfüber gestellt (eigener Befund, `bloomVerified=false`).
Darum Linse nur nach Test auf S23 und Emulator.

## 2. Neigung (Lage-Sensoren)

- Android: Game Rotation Vector nutzt kein Magnetfeld, relative Drehungen genauer. [Certain, developer.android.com/guide/topics/sensors/sensors_position]
- `sensors_plus` 7.1.1 bietet nur Accelerometer, User Accelerometer, Gyroscope, Magnetometer, Barometer – **keinen** Rotation Vector.
  [Certain, Quelltext `SensorsPlugin.kt`]
- Lizenz BSD-3 (Datei LICENSE im Paket). Manifest ohne Berechtigung. [Certain, Paketarchiv 7.1.1]
- Anforderungen: AGP ≥ 8.12.1, Kotlin 2.2.0. Unser `flutter create` (3.47.7) erzeugt AGP 9.1.0, Kotlin 2.4.0. [Certain, eigener Lauf]
- Takte: normal 200 ms, ui 66,7 ms, game 20 ms; Android garantiert den Takt nicht. [Certain, `sensor_interval.dart`, Paket-README]
- Für einen Reflex reicht die Schwerkraft-Richtung aus dem Beschleunigungssensor mit Tiefpass. Kein Gyroskop nötig. [Likely]
- Fehlt der Sensor (Emulator), liefert der Stream einen Fehler; `onError` abfangen, dann feste Lichtrichtung oben links. [Certain, README]

Plan: `FasanTilt` (fasan_ui) – Accelerometer im ui-Takt, Tiefpass α≈0,15, Ausgabe −1…1 je Achse, Ruhelage bei
Start gemerkt. Abo nur, solange ein Glas sichtbar ist und die App im Vordergrund läuft; aus bei „Bewegung reduzieren“
und im Energiesparmodus. Akkuverbrauch: nicht gemessen → Effekt-Testseite zeigt Ereignisrate. [nicht geprüft]

## 3. Filmische Übergänge

- `animations` 3.0.0 (Flutter-Team, BSD-3, Flutter ≥ 3.44): OpenContainer (Container Transform), SharedAxisTransition,
  FadeThroughTransition, FadeScaleTransition, PageTransitionSwitcher. [Certain, Paketarchiv]
- Hero (Flutter-Kern) für das Bonfoto: Liste → Bon-Ansicht → Vollbild. [Certain, api.flutter.dev/flutter/widgets/Hero-class.html]
- Federn: `SpringSimulation`/`SpringDescription` (Flutter-Kern). [Certain, api.flutter.dev]

Zuordnung (Vorschlag):
- Startseite → Rechnung: Container Transform aus der Karte.
- Schritte vor/zurück: Shared Axis X.
- Ansichtswechsel Scan/Original/Digital: Fade Through.
- Bonfoto: Hero.
- Summe stimmt: Zahl zählt hoch, Lichtkante läuft einmal um das Feld, leichte Haptik.
- Alles bei „Bewegung reduzieren“: kurzer Überblend (≤ 150 ms) statt Bewegung.
