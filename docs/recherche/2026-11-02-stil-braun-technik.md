# Stil „Braun-Technik“ (1950–80er) für Fasan – Recherche 02.11.2026

Nur lesend recherchiert (Suchen und Seitenabrufe, nichts gesendet). Quellen stehen in eckigen Klammern, Liste am Ende.
„nicht geprüft“ = keine Quelle gelesen. „Vorschlag“ = eigene Entscheidung, kein Beleg.

## Kurzfassung

- Der Stil trägt durch **Zurückhaltung und Funktion**, nicht durch Nachbau. Rams: Das T 3 „wurde nicht gestylt, es wurde gestaltet“ [Q6].
- Farbe ist **Information**: neutrale Basis (fast Schwarz, Hellgrau, Gebrochenes Weiß), ein Signal. Beispiel: gelbe Gleich-Taste am ET 66 [Q1, Q3].
- Materialien sind **ehrlich**: Metall, Holz, Acryl, Gitter. Rams verbarg Kunststoff nicht unter Textur oder Farbe [Q6, Q8, Q9].
- Gitter und Raster sind Funktion: Lautsprechergitter aus Punkten oder Linien, weil ein Gitter Schall durchlässt [Q4, Q6].
- Schrift: Braun-Beschriftung ist Akzidenz-Grotesk, Skalenziffern sind eine andere Schrift [Q7]. Frei nutzbar sind nur Ersatzschriften (IBM Plex, Doto, beide OFL).
- Gelungene heutige Beispiele (Teenage Engineering, Playdate, Nothing) arbeiten mit **festen Regeln und wenigen Mitteln** [Q10, Q11, Q12].
- Für das Handy übertragbar: Zeigerinstrument mit Trägheit, Skala mit Einrasten, Taste mit Hub, Signalpunkt als Lampe, Lochraster als Fläche.
- Haptik gibt es echt: Flutter `selectionClick` und Android `SEGMENT_TICK` (API 34) [Q14, Q15].
- Gefahr: Skeuomorphismus. Apple warf ihn mit iOS 7 raus; flache Oberflächen ohne Signale schaden aber auch [Q16, Q17].
- Regel: **Nachbilden, was etwas bedeutet, nicht wie es aussieht.** Kein Leder, keine Schrauben, keine Rost-Textur.
- Grenzen sind harte Tokens: Kontrast ≥ 4,5:1 (Text), ≥ 3:1 (Bedienflächen), Ziele ≥ 48 dp, „Animationen entfernen“ gilt.
- Empfehlung: 5 Bausteine (Abschnitt 5), Start mit Zeigersumme und Einrast-Skala.

## 1. Formensprache der Vorbilder

### Materialien
- SK 4 (1956, Rams, Gugelot): lackiertes Metall, Holz, Kunststoff; weißes Metallgehäuse, durchsichtiger Deckel [Q1].
  Der Deckel aus dünnem Plexiglas statt Holz brachte den Spitznamen „Schneewittchensarg“ [Q8].
- T 1000 (1963, Rams): Aluminium, Kunststoff, Leder [Q2].
- T 3 (1958): glatte Kunststofffläche, die jeden Fehler zeigt; Braun musste Toleranzen verbessern. Farbe: grau [Q6].
- ET 66 (1987, Rams, Lubs): schwarzer Kunststoff, runde Tasten, kleines Display oben, Schiebehülle [Q3].
- Bakelit, eloxiertes Aluminium, Lochblech als Braun-Merkmal: **nicht geprüft** (in keiner gelesenen Quelle genannt).

### Farben
- Neutrale Basis: fast Schwarz, helles Grau, Gebrochenes Weiß; Farbe sparsam und zur Information [Q5].
- ET 66: Zahlen schwarz, Rechenzeichen braun, Gleich-Taste unten rechts gelb; „farbcodiert“; Gelb zieht den Blick, weil es die häufigste Funktion ist [Q3].
- Rams scheute Farbe nicht grundsätzlich (Haartrockner HLD 4, 1970, rot/gelb/blau), wollte aber nichts, was einen Raum dominiert [Q5].
- Heutiges Braun Audio: Schwarz/Weiß als Basis, kleine Farbpunkte für Status (orange Punkte = Mikrofon aus) [Q5].
- „Das eine Orange/Grün“ als Braun-Signal: **nicht geprüft** (belegt ist Gelb am ET 66). Orange und Grün bleiben Vorschlag.

### Schrift
- Beschriftung über den Tasten des RT 20: Akzidenz-Grotesk. Die Skalenziffern sind eine andere, nicht bestimmte Schrift [Q7].
- Der Vorläufer der Braun-Hausschrift Akzidenz-Grotesk wurde meist klein gesetzt; Braun Linear (neu) hat fast gleichmäßige Strichstärke [Q18].
- Aicher (HfG) lehnte Großbuchstaben ab [Q19]. Im Deutschen ist reine Kleinschreibung falsch (Substantive); **nicht übernehmen** (Vorschlag).

### Bedienelemente
- T 3: Stellrad an der Seite, dort wo der Daumen liegt; Maße aus der Hemdtasche abgeleitet [Q6].
- T 41 (1962): Bedienelemente nach oben verlegt, Front bleibt ruhig [Q4].
- TG 60 (Prospekt 1965): zwei Anzeigen als leicht vorstehende Halbzylinder; Bedienfeld von Rams [Q9].
- Gitter: SK 1 Punktraster (versetzte Sechseck-Anordnung beim T 1000), später Linienraster, beim RT 20 im Kreis [Q4].
- Magisches Auge: grün leuchtender Kegel, dunkler Sektor wird schmaler bei richtiger Abstimmung; ab den 1960ern lösten Zeigerinstrumente es ab [Q20].
- VU-Meter: Zeiger mit Masse, 300 ms Anstieg und Abfall, 1–1,5 % Überschwingen, Skala etwa −20 bis +3 VU [Q13].
- Nixie/Glimmlampe, Kippschalter: **nicht geprüft**.

### Proportionen und Raster
- HfG Ulm: systematisch, interdisziplinär; „von der Kaffeetasse bis zur Siedlung“ (Bill) [Q21]. Stil: modern, funktional, bescheiden [Q19].
- Module: Die Höhe und Tiefe der Geräte einer Reihe passten zueinander (TG 60 in „audio 2“; G 11 stapelbar mit G 12) [Q4, Q9].
- Rams’ 10 Thesen, hier relevant: verständlich (selbsterklärend), unaufdringlich, ehrlich, im Detail durchdacht, „so wenig Design wie möglich“ [Q22].
- Konkretes Maßraster (z. B. 8-mm-Modul) der Braun-Geräte: **nicht geprüft**.

## 2. Heutige Umsetzungen

- **Apple.** Der iOS-Rechner verweist auf den ET 66; die Podcast-App ahmte einst das TG 60 nach; die iOS-7-Weltuhr spiegelt Braun-Uhren [Q23].
  Lehre: Übernommen wurden Anordnung und Farbrolle (Signal-Taste), nicht Material.
- **Teenage Engineering.** Feste Regeln: einfache Formen, RAL-Palette (~40 Farben); „Ich halte mich an Regeln … dann werde ich wieder frei“ [Q10].
  Farbe trägt Bedeutung (Orange/Rot = Aufnahme; Dreieck gelb, Quadrat blau, Kreis rot) [Q11]. Der OP-1 hat vier Drehgeber, kleinen Schirm, keine versteckten Menüs [Q10].
  Kouthoofd bevorzugt physische Bedienelemente wegen Muskelgedächtnis [Q11]. Ton: kein Audiophilen-Anspruch [Q11]. Braun-Bezug: in beiden Artikeln nicht genannt; Einfluss auf TE ist **nicht geprüft**.
- **Playdate** (mit Teenage Engineering): 1-Bit-Schirm (Sharp Memory LCD, ohne Hintergrundlicht), gelbes Gehäuse, Kurbel [Q24, Q25].
  Einschränkung ist hier das Gestaltungsmittel. Panic strich Ideen (zweiter Farbschirm, Schieber, Beschleunigungssensor) [Q25].
- **Nothing OS.** Schwarz-Weiß „weniger Farben, weniger Ablenkung“; „funktionale Ästhetik als Nordstern“ [Q26]. Hardware soll wie ein Logo wirken; Rot als sparsamer Akzent [Q27].
  Punktmatrix-Schrift Ndot: in den gelesenen Quellen nicht beschrieben, Lizenz **nicht geprüft** (vermutlich nicht frei). Ersatz: Doto (OFL) [Q28].
- **Braun-inspirierte Apps/Widgets** (Drittanbieter): nicht gezielt gesucht, **nicht geprüft**.

Was sie richtig machen: wenige Mittel, feste Regeln, Farbe mit Bedeutung, eine auffällige Eigenheit (Kurbel, Punkte), Funktion zuerst.
Haptik und Ton der Apps: **nicht geprüft** (keine Quelle gelesen).

## 3. Übertragbare Mittel fürs Handy

Alle Zuordnungen sind Vorschläge; die Belege stehen bei den Vorbildern.

| Vorbild | Handy-Mittel | Beleg Vorbild |
|---|---|---|
| Skala mit Zeiger (VU, Radioskala) | Summe, Anteil je Person, Rest als Zeiger auf Skala statt Fortschrittsbalken | Q13 |
| Magisches Auge | Eine Signalfläche zeigt „stimmt“ (Rest = 0) | Q20 |
| Statuslämpchen | Ein Punkt in Signalfarbe, nur für Zustand (offen, zugeordnet) | Q5 |
| Lochraster/Gitter | Fläche für Kopf- oder Fußbereich, rein statisch, nie unter Text | Q4, Q6 |
| Drehregler mit Rasten | Menge/Anteil in Schritten, Einrasten mit `selectionClick` | Q14 |
| Taste mit Hub | Kurzer Weg nach unten (Schatten schrumpft), Haptik beim Drücken | Q3 (runde Tasten) |
| Farbcode der Tasten | Eine Signalfarbe nur für die häufigste Handlung | Q3 |

### Bewegung
- Zeiger hat Masse: Anstieg und Abfall je ca. 300 ms, Überschwingen 1–1,5 % [Q13].
- Flutter: `SpringDescription(mass, stiffness, damping)`, auch `withDampingRatio` [Q29]. Werte unten sind Startwerte, zu messen.
- „Animationen entfernen“: `MediaQueryData.disableAnimations` [Q30]. Dann springt der Zeiger ohne Überschwingen.

### Haptik
- Flutter `HapticFeedback`: `selectionClick` (Wechsel zwischen diskreten Werten), `lightImpact`, `mediumImpact`, `successNotification`, `errorNotification`.
  Die Klasse ist „absichtlich knapp“, das Ergebnis hängt vom Gerät ab, nicht für genaue Steuerung [Q14].
- Android nativ: `SEGMENT_TICK` (Wechsel zwischen Wahlmöglichkeiten, API 34), `SEGMENT_FREQUENT_TICK` (sehr weich, kann ausfallen, API 34), `CONFIRM` (API 30), `CLOCK_TICK` (API 21), `TOGGLE_ON` (API 34) [Q15].
- Folge: Einrasten nur bei wenigen Stufen (< ca. 20) mit Tick; bei vielen Stufen kein Tick je Stufe (Doku: „weicher oder unterdrückt“) [Q15].

### Klang (optional)
- Keine Quelle zu UI-Klängen gelesen. Vorschlag: standardmäßig aus, nur kurzer Klick bei Einrasten, folgt Systemlautstärke. **nicht geprüft**.

## 4. Grenzen

- **iOS 6 → 7.** Ive: Nutzer sind mit Touch vertraut, wörtliche Nachahmung nicht mehr nötig, Gestaltung soll „aus dem Weg gehen“. Federighi: hochauflösende Schirme lassen „nirgends Verstecken“, saubere Typografie zählt [Q16].
- **Gegenseite.** NN/g: fehlende Signifier bei klickbaren Elementen sind „eines der größten Probleme“ flacher Gestaltung. Empfehlung „Flat 2.0“: leichte Tiefe, konsistente Metaphern, kein dekoratives 3D [Q17].
  Für uns: Bedienflächen brauchen sichtbare Ränder oder Hub, auch im Braun-Stil.
- **Kontrast (WCAG 2.x).** Bedienflächen-Ränder und Zustände ≥ 3:1 [Q31]. Textkontrast 4,5:1 (Norm bekannt, hier nicht neu abgerufen).
  Graue Skalenstriche auf grauem Gerät schlagen das leicht: Striche mit Bedeutung brauchen 3:1.
- **Zielgröße.** WCAG 2.2 Mindestens 24×24 CSS-px [Q32]; Fasan verlangt ≥ 48 dp (Profil „Einfach“ 60 dp, siehe CLAUDE.md von Fasan Split).
- **Farbe allein reicht nie.** Orange/Grün nie ohne Text, Form oder Position (Vorschlag; zu Farbfehlsichtigkeit keine Quelle gelesen, **nicht geprüft**).
- **Kippt zu Kitsch bei:** Textur (Leder, Holzmaserung), Schrauben, Glanzlichter, Zeiger ohne Aufgabe, Dauer-Animation, Retro-Schrift für Fließtext.
  Beleg dafür nur indirekt: Rams „nicht gestylt“ [Q6], „ehrlich“ [Q22]; Kippgrenze selbst ist Vorschlag.
- **Dunkle Fläche mit Orange:** Berechnung unten zeigt 2,93:1 (Orange `#C8460B` auf Blende `#2B2B28`). Auf dunkler Blende Bernstein statt Orange.
- **Textskalierung und „Fett“:** `textScaler`, `boldText`, `highContrast` aus `MediaQueryData` respektieren [Q30]. Skalenbeschriftung muss mitwachsen oder entfallen.

## 5. Token-Vorschläge

Alle Werte sind Vorschläge. Kontrastwerte sind selbst berechnet (WCAG-Formel für relative Helligkeit) am 02.11.2026.

### Farben, hell („Gerät“)
| Token | Hex | Kontrast |
|---|---|---|
| `bg` Gerätegrau | `#DCDBD5` | – |
| `surface` | `#ECEBE6` | – |
| `panel` Blende | `#2B2B28` | zu `surface` 11,9 |
| `ink` | `#1D1D1B` | auf bg 12,17; auf surface 14,14 |
| `ink2` | `#4F4F4A` | auf bg 5,94; auf surface 6,90 |
| `line` Rand/Skala | `#74736C` | auf bg 3,43; auf surface 3,99 |
| `signal` Orange | `#C8460B` | auf bg 3,49; surface 4,06 (nur Fläche); weiße Schrift darauf 4,84 |
| `signalText` | `#A93A08` | auf surface 5,34; bg 4,59 |
| `ok` Grün | `#2F7A4D` | auf bg 3,77; surface 4,39 (nur Fläche, Text in `ink`) |

### Farben, dunkel („Blende“)
| Token | Hex | Kontrast |
|---|---|---|
| `bg` | `#1C1C1A` | – |
| `surface` | `#272725` | – |
| `ink` | `#E7E5DD` | auf bg 13,53; surface 11,87 |
| `ink2` | `#B3B1A8` | auf bg 7,94; surface 6,96 |
| `line` | `#86857E` | auf bg 4,61; surface 4,04 |
| `signal` Orange | `#FF7A2E` | auf bg 6,56; surface 5,75; dunkle Schrift darauf 6,56 |
| `ok` Grün | `#5CC48A` | auf surface 6,93 |
| `lamp` Bernstein | `#FFB347` | auf bg 9,58 |

Regel: höchstens **ein** Signal je Bildschirm (Vorbild: eine gelbe Taste [Q3]); Grün nur für „erledigt“.
Ein „Hochkontrast“-Profil (`highContrast`) setzt `line` auf `ink` [Q30].

### Schriften (nur frei)
| Rolle | Schrift | Lizenz | Quelle |
|---|---|---|---|
| Text, Tasten, Beschriftung | IBM Plex Sans (auch Condensed) | SIL OFL | Q33 |
| Zahlen auf Skalen, Beträge | IBM Plex Mono (Ziffern gleich breit) | SIL OFL | Q33 |
| Punktanzeige (nur Zierziffern, ≥ 24 sp, nie Fließtext) | Doto, Raster 6×10, Achsen Punktgröße/Rundung | SIL OFL 1.1 | Q28 |

- Akzidenz-Grotesk ist die Braun-Schrift [Q7]; Lizenz **nicht geprüft** (vermutlich kommerziell). Nicht einbinden.
- Weitere Kandidaten (Inter, Barlow, B612, D-DIN): **nicht geprüft**.
- Plex ist eher „Technik“ als Braun-neutral; Abgleich mit Skalenziffern: Vorschlag per Bildschirmfoto prüfen.
- Ziffern: `FontFeature.tabularFigures()` für Summen. Betrag immer in Plex Mono, nie in Doto allein.

### Form, Linien
- Radien: Taste rund (Kreis, wie ET 66 [Q3]); Karte 6 dp; Panel 12 dp; Skalenfeld 2 dp.
- Linien: Haarlinie 1 dp (`line`); Skalenstrich 2 dp; drei Längen (klein 6, mittel 10, groß 16 dp).
- Raster: 4-dp-Grundmaß; Abstände 4/8/16/24. Lochraster 6 dp Mitte-Mitte, Punkt 2 dp, versetzt (Vorbild T 1000 [Q4]).
- Ziele ≥ 48 dp (Profil „Einfach“ 60 dp); Taste mit sichtbarem Rand `line`.

### Bewegung
| Token | Wert | Hinweis |
|---|---|---|
| `needle.spring` | Masse 1, Dämpfungsgrad 0,8 | Eigene Rechnung: ζ = 0,8 ergibt ca. 1,5 % Überschwingen (Standardformel 2. Ordnung, nicht gesondert belegt); passt zu VU 1–1,5 % [Q13]. Steifigkeit Startwert 300, zu messen |
| `key.down` | 60 ms, `Curves.easeOut` | Hub 2 dp |
| `key.up` | 120 ms | |
| `detent.snap` | 90 ms, kein Überschwingen | Rasten |
| `lamp.on` | 80 ms an, 200 ms aus | Glimmlampe nicht geprüft; hier nur Vorschlag |
| `reduced` | alles 0 ms, Zeiger springt | `disableAnimations` [Q30] |

### Haptik
| Ereignis | Flutter | Android nativ (falls später Plugin) |
|---|---|---|
| Einrasten (< 20 Stufen) | `selectionClick` | `SEGMENT_TICK` (API 34) |
| Viele Stufen (Schieben) | kein Tick je Stufe, Tick an Marken | `SEGMENT_FREQUENT_TICK`, kann ausfallen |
| Taste drücken | `lightImpact` | `VIRTUAL_KEY` |
| Zuordnung bestätigt | `successNotification` | `CONFIRM` (API 30) |
| Summe stimmt nicht | `errorNotification` | nicht geprüft |
Haptik stets abschaltbar; Systemeinstellung gilt. Gerätewirkung variiert [Q14].

## 6. Fünf Bausteine

1. **Zeigersumme.** Halbkreis-Skala (−20…+3-artig nur als Form, hier 0…Rechnungssumme), Zeiger mit Feder (`needle.spring`).
   Er zeigt „zugeordnet / Summe“. Ziffern groß in Plex Mono daneben, **der Zeiger ist nie die einzige Information**. Skalenstriche `line`, Null und Ende in `ink`. Bei „Animationen entfernen“ springt er.
2. **Rest-Auge.** Kleine Fläche (Kreis oder Sektor) wie das magische Auge: dunkler Sektor wird schmaler, je mehr Posten zugeordnet sind; bei Rest 0 volle Fläche in `ok`. Zusätzlich Text „Rest 0,00 €“ [Q20 als Vorbild, Form Vorschlag].
3. **Einrast-Skala.** Waagerechte Skala für Anteile oder Mengen mit Rasten (1/2, 1/3 …). Zeiger snappt (`detent.snap`), `selectionClick`. Bedienbar auch mit Plus/Minus-Tasten (jede Geste hat einen sichtbaren Zwilling, siehe CLAUDE.md Fasan Kamera).
4. **Signaltaste.** Eine runde oder breite Taste in `signal` je Bildschirm, nur für die häufigste Handlung (Zuordnen, Weiter). Hub 2 dp, `lightImpact`, weiße bzw. dunkle Schrift mit ≥ 4,5:1. Alle anderen Tasten grau mit Rand [Q3].
5. **Lampenreihe + Lochfläche.** Pro Person ein Lämpchen (aus / `lamp` an = hat Posten bekommen), mit Initiale als Text. Dahinter statisches Lochraster nur im Kopfbereich (nie unter Text, 1 Farbe, ohne Glanz). Reine Zustandsanzeige [Q5, Q4].

## 7. Offene Punkte (nicht geprüft)

- Bakelit, eloxiertes Aluminium, Lochblech als Braun-Merkmale; Maßraster der Geräte.
- Das „eine“ Orange oder Grün bei Braun (belegt: Gelb am ET 66).
- Nixie/Glimmlampe, Kippschalter; Haptik und Ton der Vorbild-Apps; Braun-inspirierte Apps.
- Lizenz von Ndot und Akzidenz-Grotesk; Eignung von Inter, Barlow, B612, D-DIN.
- Ob Doto-Ziffern auf kleinen Phones lesbar sind (Bildschirmfoto-Test, Emulator).
- Verhalten der Haptik auf Geräten (S23 und andere): messen.

## Quellen (alle nur gelesen)

- Q1 MoMA, Radio-Phonograph SK 4/10: https://www.moma.org/collection/works/2649
- Q2 Brooklyn Museum, World Receiver T 1000: https://brooklynmuseum.org/en-GB/objects/170035
- Q3 V&A, Braun ET 66 (O1360553): https://collections.vam.ac.uk/item/O1360553
- Q4 Core77, A History of Braun Design Part 3: https://www.core77.com/posts/24768/A-History-of-Braun-Design-Part-3-Audio-Products
- Q5 Braun Audio, Colour choices: https://www.braun-audio.com/en-ES/stories/design/braun-colour-choices/
- Q6 Limited Hype, Braun T3: https://limitedhype.pages.dev/stories/0046-braun-t3
- Q7 Fonts In Use, Braun RT 20: https://www.fontsinuse.com/uses/6957/braun-rt-20
- Q8 V&A, Phonosuper SK55 (O168285): https://collections.vam.ac.uk/item/O168285
- Q9 Design und Text, TG 60: https://www.designundtext.com/en/2.1.24_braun-design-tg60-rams-pbdd.php
- Q10 Limited Hype, Teenage Engineering: https://limitedhype.pages.dev/stories/0058-teenage-engineering-and-their-design-philosophy
- Q11 SFMOMA, Interview Jesper Kouthoofd: https://www.sfmoma.org/read/stay-curious-stay-naive-an-interview-with-teenage-engineering-jesper-kouthoofd/
- Q12 Siehe Q24–Q27.
- Q13 Wikipedia, VU meter: https://en.wikipedia.org/wiki/VU_meter
- Q14 Flutter API, HapticFeedback: https://api.flutter.dev/flutter/services/HapticFeedback-class.html
- Q15 Android, HapticFeedbackConstants: https://developer.android.com/reference/android/view/HapticFeedbackConstants
- Q16 Cult of Mac, Ive zu iOS 7: https://www.cultofmac.com/246312/jony-ive-explains-why-he-decided-to-gut-skeuomorphism-out-of-ios/
- Q17 NN/g, Flat design (Spiegel): https://hn.jakechampion.name/reader/https://www.nngroup.com/articles/flat-design
- Q18 UX Planet, Braun Linear: https://uxplanet.org/braun-iconwerk-braun-linear-74e12d5d8627
- Q19 Kundnani, The Ulm aesthetic: https://hanskundnani.com/2016/09/01/the-ulm-aesthetic/
- Q20 Wikipedia, Magic eye tube: https://en.wikipedia.org/wiki/Magic_eye_tube
- Q21 Wallpaper, Ulm-Modell: https://wallpaper.com/design/the-ulm-model-of-product-design-is-explored-at-raven-row-london
- Q22 Vitsœ, Good design: https://vitsoe.com/gb/about/good-design
- Q23 Wikipedia, Dieter Rams: https://en.wikipedia.org/wiki/Dieter_Rams
- Q24 Wikipedia, Playdate: https://en.wikipedia.org/wiki/Playdate_(console)
- Q25 GamesRadar, Playdate: https://gamesradar.com/playdate-how-the-publishers-of-untitled-goose-game-built-a-console-designed-to-spark-pure-joy
- Q26 Business Today, Nothing OS (Hoyss): https://www.businesstoday.in/technology/story/exclusive-ahead-of-phone-2a-launch-nothing-os-head-mladen-hoyss-explains-its-ui-choices-418781-2024-02-24
- Q27 Creative Bloq, Nothing „wie Logos“: https://www.creativebloq.com/design/product-design/why-nothing-designs-its-phones-like-logos
- Q28 Fontsource, Doto: https://fontsource.org/fonts/doto/about
- Q29 Flutter API, SpringDescription: https://api.flutter.dev/flutter/physics/SpringDescription-class.html
- Q30 Flutter API, MediaQueryData: https://api.flutter.dev/flutter/widgets/MediaQueryData-class.html
- Q31 W3C, Non-text Contrast: https://w3c.github.io/wcag21/understanding/non-text-contrast
- Q32 W3C, Target Size (Minimum): https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- Q33 Wikipedia, IBM Plex: https://en.wikipedia.org/wiki/IBM_Plex

Hinweise zur Quellenlage: Q10 und Q11 erwähnen Braun nicht. Die Wikipedia-Seite zu Rams (Q23) nennt Jahre, aber keine Farben oder Materialien.
Einige Seiten (designundtext T 1000, Fonts In Use Braun-Übersicht) waren nicht abrufbar; deren Inhalt fehlt hier.
