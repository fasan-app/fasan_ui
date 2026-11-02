# Gestaltungssystem Fasan – Spezifikation (Stand 02.11.2026)

Grundlage: `docs/recherche/2026-11-01-design-grundlagen.md`, `2026-11-02-farbe-verlauf-aufmerksamkeit.md`,
`2026-11-02-glas-neigung-bewegung.md`. Zahlen ohne Beleg sind als „gesetzt“ markiert: eigene Wahl, auf dem Gerät prüfen.

## 1. Haltung

- Rams: so wenig Gestaltung wie möglich. Jede Linie, jeder Effekt hat eine Aufgabe.
- Bauhaus: Raster, klare Rangfolge, eine Signalfarbe.
- Apple 2026: Inhalt unten, Bedienung schwebt als Glas darüber. Licht statt Linien zeigt Form.
- Film: Korn, Wackeln und Licht geben Stimmung. Sie liegen **hinter** dem Inhalt, nie über Text.

## 2. Schichten (von hinten nach vorn)

| Ebene | Inhalt | Effekte |
|---|---|---|
| 0 Grund | animierter Farbverlauf (3 weiche Flecken) | Korn, Wackeln, Lichteinfall |
| 1 Inhalt | Karten, Bon, Listen – undurchsichtige Flächen | keine; Text bleibt ruhig |
| 2 Bedienung | Leisten, Hauptknopf, Schalter – Glas | Lichtkante (Neigung), Schatten, Tönung, Berührungslicht |
| 3 Rückmeldung | Glow an einem Element, Ring-Impuls, Zahl zählt | einmalig, dann ruhig |
| 4 Film (nur filmische Stile) | Ecken, Datenzeilen, Abtastlinie | eigene Overlays |

Wählbar: Korn und Wackeln „nur Grund“ (Standard) oder „ganzes Bild“.

## 3. Farbe – drei Entwürfe

Werte aus `2026-11-02-farbe-verlauf-aufmerksamkeit.md` §5, Kontraste dort geprüft.

| | A Papier/Orange | B Nebel/Tiefblau | C Salbei/Ton |
|---|---|---|---|
| Akzent-Einstellung | Signal | Kobalt | Salbei |
| Grund hell/dunkel | #F4F2EE / #121211 | #F5F6F8 / #0E1014 | #F6F5F1 / #101412 |
| Fläche | #FFFFFF / #1C1B1A | #FFFFFF / #171A20 | #FFFFFF / #181D1A |
| Akzent | #C2410C / #FF8A4C | #2F55D4 / #7C9BFF | #2F6B55 / #7CC4A4 |
| Verlaufsflecken | Akzent 10 %, Sand 14 %, Rosé 8 % | Akzent 12 %, Eis 14 %, Flieder 8 % | Akzent 10 %, Ton 12 %, Moos 8 % |

Verlauf: Periode 32 s (gesetzt, Rahmen 20–40 s), Wege ≤ 10 % der Breite, Unschärfe der Flecken = halbe Bildbreite.
Text liegt immer auf Fläche ≥ 90 % Deckkraft. Statisch bei reduzierter Bewegung und beim Sparen.

## 4. Glas

- Blur σ 18 (Ruhe + Glas) / 28 (Volles Glas). Tönung 68 % / 42 %.
- Lichtkante: Rand 1,2 dp, Verlauf aus zwei Lichtpunkten, gegenüberliegend; Winkel = Grundwinkel (oben links, −45°)
  plus Neigung × 35°. Helligkeit innen weiß 55 % (hell) / 32 % (dunkel), Gegenseite 12 %.
- Schatten: eng (y 1, Blur 2, 8 %) + weit (y 10, Blur 30, 10 % hell / 35 % dunkel).
- Berührung: Lichtfleck an der Fingerposition, Radius 90 dp, weiß 18 %, Ein 120 ms, Aus 420 ms; Feder 0,97 → 1.
- Erscheinen: Lichtkante 0 → 1 und Blur 0 → σ in 320 ms (materialisieren statt ausblenden).
- Hauptknopf: getönt (Akzent 100 %), Lichtkante wie Glas, Glow in Akzent.
- Transparenz reduzieren (App-Einstellung, und automatisch beim Sparen): undurchsichtig, Haarlinie.
- Kontrast erhöhen (`MediaQuery.highContrast`): undurchsichtig, Rand 1,5 dp in Textfarbe.

## 5. Neigung

Game Rotation Vector (ohne Magnetfeld), 30 Hz, eigener Kanal im fasan_ui-Plugin; Rückfall Beschleunigungssensor.
Tiefpass α 0,15; ±20° = voller Ausschlag; Ruhelage gleitet in 4 s nach (wer das Handy anders hält, sieht wieder Mitte).
Aus: „Bewegung reduzieren“, Sparen, App im Hintergrund, kein Glas sichtbar.

## 6. Filmeffekte (alle einzeln regelbar, alle abschaltbar)

| Effekt | Standard | Regler | Umsetzung |
|---|---|---|---|
| Korn | an, animiert, Stärke 0,35 | Stärke, Größe 1–4 px, Tempo 0–24 Bilder/s, Ebene | Shader ohne Bildlesen |
| Wackeln | an, 0,4 | Stärke (bis 3 px), Ebene | Verschiebung, zwei Sinus |
| Glow | an, 0,5 | Stärke | weicher Schein um Hauptknopf und Summe (Blur-Schatten, kein Bildlesen) |
| Halation | an, 0,35 | Stärke | warmer roter Saum um helle Elemente |
| Überstrahlen | an, 0,25 | Stärke | Lichtfleck aus der Lichtrichtung in den Grund |
| Lichteinfall | an | an/aus | heller Streifen wandert alle 14 s einmal über den Grund |
| Verlauf | an | an/aus | Ebene 0 |
| Neigungslicht | an | an/aus | Abschnitt 5 |

Glow, Halation und Überstrahlen nutzen nur `MaskFilter.blur`/Schatten. Das bisherige Bildschirm-Shader-Bloom bleibt aus
(`bloomVerified=false`, Befund Emulator/S23).

## 7. Bewegung

| Wechsel | Übergang | Dauer |
|---|---|---|
| Startseite → Rechnung | Container Transform aus der Karte | 420 ms |
| Schritt vor/zurück | Shared Axis X (30 dp, Überblenden) | 320 ms |
| Ansicht Scan/Original/Digital | Fade Through | 260 ms |
| Bonfoto Liste → Ansicht | Hero | 320 ms |
| Summe stimmt | Zahl zählt, Ring-Impuls 600 ms, Haptik leicht | einmalig |
| Knopf | Feder 0,97, Licht unter dem Finger | – |

Reduzierte Bewegung: Überblenden ≤ 150 ms, keine Wege, keine Federn.

## 8. Prüfen

Effekt-Testseite (Einstellungen → Aussehen → Effekte prüfen): jeder Effekt einzeln, Neigungswerte, Ereignisrate,
Bildrate. Abnahme: Emulator-Bildschirmfotos A/B/C hell und dunkel mit echtem Bon, dann S23.
