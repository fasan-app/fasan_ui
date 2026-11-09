# Farbe, Verlauf und Aufmerksamkeit für eine ruhige, hochwertige Rechnungs-App

Stand: 2026-11-02. Sprache: Deutsch. Quellen nummeriert am Ende. Alles, was ich nicht selbst gelesen habe, steht als „nicht geprüft“.

## Kurzfassung

1. Belegt: Farbe, Bewegung, Größe und Ausrichtung lenken Aufmerksamkeit stark [7]. Farbänderung allein gilt dort als „wahrscheinlich kein“ Leitmerkmal [7].
2. Ein ruhiger Akzent auf neutralem Grund wirkt stärker als viele Farben. Android rät: wenige Farbrollen, Flächen neutral [20]. Apple rät: Farbe auf Glas sparsam, Markenfarbe in die Inhaltsebene [4].
3. Grau-in-Grau wirkt schlechter: Farbige Oberflächen schlugen Graustufen bei Attraktivität und Nutzungsqualität [14]. Entsättigte Seiten wurden als weniger vertrauenswürdig bewertet [11]. Also: gedämpft, nicht farblos.
4. Animierte Verläufe: Es gibt keine belastbare Studie zu „ruhigen Hintergrundverläufen“ (nicht geprüft). Regeln unten sind Vorschläge aus WCAG [1][16] und Apple-Grundsätzen [3].
5. WCAG 2.2.2: Bewegung, die automatisch startet, länger als 5 s läuft und neben anderem Inhalt steht, braucht Pause/Stopp/Aus [1]. Dekorverläufe daher ruhig, abschaltbar, bei „Animationen entfernen“ statisch.
6. Flutter: `disableAnimations` spiegelt nur Android „Animationen entfernen“, nicht iOS Bewegung reduzieren; iOS braucht `AccessibilityFeatures.reduceMotion` [10]. Beide abfragen.
7. Aufmerksamkeit lenken: Eine Handlung pro Bildschirm, ein Akzent, einmalige kurze Bewegung statt Dauerpulsieren. Banner-Blindheit: Alles, was wie Werbung aussieht (Animation, bunte Kästen), wird überlesen [6].
8. Kontrast: WCAG 2 (4,5:1 Text, 3:1 Bedienelemente [15]) bleibt der Maßstab; WCAG 3 hat noch keinen Algorithmus, APCA ist nur Zusatzprüfung [2].
9. Trends: Pantone 2026 „Cloud Dancer“ (11-4201), ein ruhiges Weiß [5]. WGSN/Coloro 2027 „Luminous Blue“ [18]. Passt zu Neutral plus ein Akzent; Prognosen sind kein Nutzerbeleg [19].
10. Drei Paletten (Papier/Orange, Nebel/Blau, Salbei/Grün) mit gerechneten Kontrasten und Zahlenregeln für Verlauf und Aufmerksamkeitszustände: siehe Abschnitt 5 und 6.

## 1. Animierte Verläufe und Mesh-Gradients

### Was belegt ist
- Ästhetik beeinflusst wahrgenommene Nutzbarkeit (Aesthetic-Usability-Effekt, Kurosu/Kashimura 1995) [13]. Die Übersicht warnt: wenige Studien, teils aus zweiter Hand [13].
- Farbe schlug Dimensionalität: 2D-Farbe war in zwei mobilen Apps am beliebtesten; 3D-Schatten senkte in der Transport-App die Bewertung. Nur Screenshots, überwiegend deutsche Studierende [14].
- Apple: Liquid Glass gehört in die Funktionsebene (Leisten, Bedienelemente), nicht in die Inhaltsebene. Sparsam einsetzen, sonst lenkt es vom Inhalt ab [3]. Für den Hintergrund nimmt man Standardmaterialien [3].
- Apple: Bei klarem Glas über hellem Inhalt eine dunkle Abdunklung von 35 % erwägen [3].
- Bewegung am Rand zieht Blick: Bewegung ist ein belegtes Leitmerkmal der Aufmerksamkeit [7]. Ein dauerhaft bewegter Hintergrund konkurriert also mit der Aufgabe (Folgerung, nicht direkt gemessen).
- Langsame Änderungen werden oft nicht bemerkt (Change Blindness, z. B. ein Gebäude, das über 12 s verschwindet) [22]. Sehr langsame Verläufe stören daher kaum, signalisieren aber auch nichts.

### Nicht belegt (nicht geprüft)
- Akku-/GPU-Kosten animierter Mesh-Gradients in Flutter: Suche fand nur Paket-Seiten, keine Messung. Vor Einsatz selbst messen (Profil-Modus, echtes Gerät).
- Studien zu „Freude“ oder „Orientierung“ durch Hintergrundverläufe: keine gefunden.
- Material 3 Expressive (Forschungsbasis, Motion-Richtlinien): Seiten nicht abrufbar bzw. nur Zweitquellen; nicht geprüft.
- Apple-HIG-Seite „Motion“: nicht abrufbar; nicht geprüft.

### Regeln (Vorschlag, aus [1][3][16][22] abgeleitet; Zahlen nicht geprüft)
- Statisch ist der Normalfall. Verlauf nur auf Startseite/Zusammenfassung, nie hinter Listen oder Eingabefeldern.
- Bewegung nur sehr langsam: eine Periode 20–40 s, Verschiebung höchstens 8–12 % der Bildschirmbreite, Farbwechsel höchstens ΔL 3–4 (LCH) zwischen Stützpunkten. Kein Zucken, keine Beschleunigung.
- Kontrast darf nie vom Verlauf abhängen: Text liegt auf einer Fläche, deren schlechtester Punkt noch 4,5:1 erreicht.
- Läuft die Bewegung länger als 5 s, braucht sie einen Aus-Schalter in der App [1]. Zusätzlich System-Einstellung folgen (Abschnitt 4).
- Pausieren bei Eingabe (Tastatur offen, Scrollen) und bei App im Hintergrund.
- Fallback: Statisches Bild des Verlaufs (vorgerendert), wenn Energiesparmodus, „Animationen entfernen“ oder schwaches Gerät.

## 2. Aufmerksamkeit auf einen Bereich lenken

### Was die Forschung sagt
- Undoubted guiding attributes: Farbe, Bewegung, Ausrichtung, Größe [7]. Wahrscheinlich: Helligkeits-Onset, Form u. a. [7]. „Farbänderung“ steht bei den wahrscheinlichen Nicht-Merkmalen [7]. Heißt: Ein Element, das sich in Farbe von der Umgebung abhebt, fällt auf; ein langsamer Farbwechsel allein nicht sicher.
- Change Blindness: Wer Änderungen erwartet nicht, übersieht sie leicht, vor allem wenn die Bewegungssignale gestört sind oder die Änderung langsam passiert [22]. Ein Zustandswechsel ohne klares Signal bleibt unbemerkt.
- Banner-Blindheit (NN/g): Nutzer übergehen werbeähnliche Bereiche. Als werbetypisch gelten Animation, kleine farbige Kästen, auffällige Formatierung [6]. Beispiel: 1 von 148 Fixationen auf der rechten Spalte [6]. Auf dem Handy werden große, auffällige Grafiken als Werbung überscrollt, auch bei relevantem Inhalt [6]. NN/g misst dabei keine Wirkung von Animation selbst [6].
- Gelernte Elemente (Navigation, Überschriften) werden beachtet [6]. Also: Handlungsaufforderung als normales Bedienelement gestalten, nicht als „Banner“.

### Barrierefreiheit
- 1.4.11 Nicht-Text-Kontrast (AA): Bedienelemente, Fokus- und Zustandsanzeigen mindestens 3:1 gegen die Umgebung [15].
- 1.4.1 Farbe nicht als einziges Mittel: W3C-Seite nicht gelesen, nicht geprüft. Apple und Android sagen dasselbe: Farbe mit Text oder Form koppeln [4][20].
- 2.2.2 Pause/Stopp/Ausblenden (A): gilt bei automatischer Bewegung über 5 s neben anderem Inhalt [1].
- 2.3.3 Animation aus Interaktionen (AAA): Bewegung, die durch Nutzeraktion ausgelöst wird, muss abschaltbar sein, außer sie ist wesentlich [16]. Quelle ist eine Zweitseite, W3C-Original nicht gelesen.
- 2.3.1 Blitzen (A): nicht mehr als 3 Blitze pro Sekunde, sonst unter der Schwelle (Helligkeitswechsel ≥ 10 %) [17]. Pulsieren deutlich langsamer halten.

### Mittel nach Stärke (Einordnung, Vorschlag; Stärken nicht gemessen)
| Mittel | Wirkung | Risiko |
|---|---|---|
| Badge/Punkt mit Zahl | leise, bleibt sichtbar | wird bei Dauer ignoriert |
| Akzent-Rand/Fläche (statisch) | klar, barrierearm | verliert Wirkung, wenn mehrere |
| Einmaliger Ring/Glow beim Erscheinen | zieht Blick über Bewegung/Onset [7] | nur einmal sinnvoll |
| Dauerpulsieren | maximal auffällig | Banner-Blindheit [6], 2.2.2 [1], Ablenkung |
| Farbwechsel des Hintergrunds | gering [7] | Change Blindness [22] |

### Regeln (Vorschlag, Zahlen nicht geprüft)
- Pro Bildschirm höchstens ein Bereich mit Aufmerksamkeitszustand.
- Ablauf: Erscheinen 240 ms, ein Ring-Impuls 600 ms (Deckkraft 0 → 0,35 → 0, Blur 0 → 12 px), danach statischer Zustand. Kein Dauerpulsieren.
- Statischer Zustand: Rand 2 dp in Akzent (3:1 gegen Umgebung [15]), Hintergrund Akzent mit 8–12 % Deckkraft, plus Text/Symbol („Offen“, Ausrufezeichen), nie Farbe allein [4][20].
- Wiederholung: Nach 20 s Inaktivität höchstens ein weiterer Impuls, danach nie wieder in dieser Sitzung. Bei „Animationen entfernen“: kein Impuls, nur statischer Zustand.
- Badge: Zahl statt reinem Punkt, ab 1 sichtbar, Größe Ziel mindestens 48 dp Tippfläche (Projektregel).

## 3. Farbschemata

### Gedämpft vs. kräftig
- Farbige Oberflächen schlugen Graustufen in Attraktivität, Gefallen und Nutzungsqualität; Graustufen wurden als „stumpf, schwer unterscheidbar“ beschrieben [14].
- Entsättigung senkte das Vertrauen (122 Teilnehmende, 108 ausgewertet), ohne die Anziehungskraft messbar zu ändern. Sättigung erhöhte sie nicht signifikant [11]. Ableitung: Mittlere Sättigung, nicht Pastell-grau, nicht Neon.
- Android: Zu viele Signalfarben verwirren, zu viele Zierfarben erdrücken; Flächen neutral, Primärfarbe für wichtigste Handlung; „oversaturated look“ vermeiden [20].
- Apple: Eigene Farben in hell, dunkel und erhöhtem Kontrast liefern; Systemfarben nicht fest verdrahten [4]. Hinweis: Apple-Farbseite nur über eine Spiegelung gelesen [4].
- Linear: Theme aus nur drei Größen (Basis, Akzent, Kontrast) in LCH; weniger blaue „Chrome“-Farbe für neutrale, zeitlose Wirkung [21]. Das ist eine Teamentscheidung, kein Nutzerbeleg.

### Trends 2026/27
- Pantone 2026: Cloud Dancer, 11-4201, „billowy, balanced white“, Ruhe und Neubeginn [5]. Kritik stand nicht in dieser Quelle [5].
- WGSN/Coloro 2027: Luminous Blue (125-28-38); Begleitfarben Energy Orange, Pop Pink, Meadowland Green, Clay [18].
- Digitale Deutungen (Blog, Zweitquelle): gedämpftes Grün als Neutralfarbe, ein Blau-Akzent, warme Erdtöne, bewusste Off-White-Töne; viele Mittelton-Trendfarben scheitern als Text [19].
- Pantone 2027: laut [19] im Oktober 2026 noch nicht verkündet; nicht geprüft.
- Top-Apps (Splitwise, Tricount, Things, Revolut, Arc): konkrete Farbwerte nicht belegt, Seiten nicht abrufbar bzw. nur Fremddeutungen. nicht geprüft. Nicht übernehmen.

### Dunkelmodus
- Keine Polarität ist für alle besser; Leistung und Vorliebe stimmen oft nicht überein. Empfehlung der Studie (Crowdsourcing, Diagramme, nicht Apps): beides anbieten [12].
- Folge: Hell, Dunkel und System. Dunkel nicht reines Schwarz (Vorschlag, Begründung nicht geprüft), Akzent im Dunkeln heller.

### Kontrast: WCAG 2 vs. APCA
- WCAG 3: Der Kontrast-Algorithmus ist laut Editor-Entwurf vom 8. April 2026 noch offen; APCA wurde 2023 aus dem Entwurf entfernt [2]. WCAG 3 frühestens um 2030 [2].
- Praxis: WCAG-2-Werte erfüllen; APCA höchstens zusätzlich prüfen [2]. Fürs Projekt: Text 4,5:1, Bedienelemente und Zustände 3:1 [15].

## 4. Bewegung reduzieren in Flutter
- Android: `MediaQuery.disableAnimationsOf(context)` spiegelt „Animationen entfernen“. iOS setzt dieses Flag nicht; dort `PlatformDispatcher.instance.accessibilityFeatures.reduceMotion` [10].
- Regel: `reduce = disableAnimations || reduceMotion || appEinstellung`. Dann Verlauf statisch, Impuls aus, Übergänge auf Überblenden ≤ 150 ms.
- Antwortzeiten nach NN/g: Grenzen 0,1 / 1 / 10 s [8] (Erklärung der Stufen auf der Seite nicht enthalten). Übergänge 150–300 ms sind Vorschlag, nicht geprüft.

## 5. Drei Palettenvorschläge

Kontraste mit WCAG-2-Formel selbst berechnet (Python, 2026-11-02). Werte sind Vorschläge; Gefallen und Wirkung nicht mit Nutzern geprüft.

### A „Papier und Orange“ (Rams/Braun, Bauhaus)
| Rolle | Hell | Dunkel |
|---|---|---|
| Grund | #F4F2EE | #121211 |
| Fläche | #FFFFFF | #1C1B1A |
| Text | #1B1B1A (15,4:1) | #EDEBE7 (15,7:1) |
| Text zweitrangig | #5C5A56 (6,2:1) | #A5A29B (7,4:1) |
| Akzent | #C2410C (4,6:1 auf Grund; weiß darauf 5,2:1) | #FF8A4C (8,0:1) |
| Text auf Akzent | #FFFFFF | #121211 (8,0:1) |
Charakter: warm, klar, am nächsten an Braun-Orange. Orange kann als Warnung gelesen werden; für „Du bekommst Geld“ eigene Grünfarbe nötig.

### B „Nebel und Tiefblau“ (Apple/Linear-nah)
| Rolle | Hell | Dunkel |
|---|---|---|
| Grund | #F5F6F8 | #0E1014 |
| Fläche | #FFFFFF | #171A20 |
| Text | #14161A (16,8:1) | #E8EAEE (15,8:1) |
| Text zweitrangig | #555B66 (6,3:1) | #9AA1AD (7,3:1) |
| Akzent | #2F55D4 (5,8:1; weiß darauf 6,2:1) | #7C9BFF (7,2:1) |
| Text auf Akzent | #FFFFFF | #0E1014 (7,2:1) |
Charakter: kühl, neutral, am sichersten. Wirkt austauschbar; passt zu „Luminous Blue“ 2027 [18].

### C „Salbei und Ton“ (gedämpft, Pantone-nah)
| Rolle | Hell | Dunkel |
|---|---|---|
| Grund | #F6F5F1 | #101412 |
| Fläche | #FFFFFF | #181D1A |
| Text | #1D211E (14,9:1) | #E6EAE6 (15,3:1) |
| Text zweitrangig | #575D58 (6,2:1) | #9AA39C (7,2:1) |
| Akzent | #2F6B55 (5,7:1; weiß darauf 6,3:1) | #7CC4A4 (9,1:1) |
| Text auf Akzent | #FFFFFF | #101412 (9,1:1) |
| Hinweis (Aufmerksamkeit) | #9A5B00 (5,0:1 auf Grund) | #F2B24B (10,0:1 auf A-Dunkel) |
Charakter: ruhig, passt zu Cloud-Dancer-Off-White [5] und Salbei-Trend [19]. Grün als Akzent kollidiert mit „bekommt Geld“; dann Bernstein für „offen/Handlung“ nutzen und Rot/Grün nie allein trennen [20].

Empfehlung (Meinung, nicht gemessen): C für „ruhig und hochwertig“, A für stärkste Eigenständigkeit, B als Fallback. Entscheidung gehört in `ENTSCHEIDUNGEN.md`.

## 6. Regeltabelle (Vorschläge, Zahlen nicht geprüft)

| Thema | Wert |
|---|---|
| Hintergrundverlauf: Periode | 20–40 s, Easing linear/sinus |
| Verlauf: Verschiebung | ≤ 8–12 % Breite |
| Verlauf: Helligkeitsunterschied | ΔL ≤ 3–4 (LCH) |
| Verlauf: Blur der Farbflecken | 60–120 px (weich, kein Muster) |
| Verlauf: Deckkraft unter Text | Text immer auf Fläche mit ≥ 90 % Deckkraft oder 4,5:1 im schlechtesten Punkt |
| Glas/Material hinter Leisten | Blur 20–30 px, Abdunklung bis 35 % bei hellem Inhalt [3] |
| Zustandsübergang | 200–250 ms, ease-out |
| Erscheinen eines Handlungsbereichs | 240 ms, einmaliger Ring 600 ms, Deckkraft max. 0,35, Blur max. 12 px |
| Dauerpulsieren | verboten |
| Blinken | < 3 pro Sekunde [17], praktisch keins |
| Statischer Aufmerksamkeitsrand | 2 dp, ≥ 3:1 [15], plus Text/Symbol |
| Flächenfüllung Akzent | 8–12 % Deckkraft |
| Bei reduzierter Bewegung | Verlauf statisch, kein Impuls, Überblenden ≤ 150 ms |
| Maximal gleichzeitig | 1 Aufmerksamkeitsbereich pro Bildschirm |

## 7. Lücken (nicht geprüft)
- Akku- und GPU-Kosten animierter Verläufe in Flutter/Impeller.
- Studien zu Wirkung ruhiger Verläufe auf Vertrauen oder Orientierung.
- Material 3 Expressive, Apple HIG „Motion“ und „Accessibility“ im Original.
- Farbwerte und Entscheidungen von Splitwise, Tricount, Things, Revolut, Arc.
- WCAG 1.4.1 im W3C-Original.
- Alle Zahlen in Abschnitt 1, 2 und 6: eigene Vorschläge, per Emulator und Nutzertest prüfen.

## Quellen
1. W3C, Understanding SC 2.2.2 Pause, Stop, Hide: https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide
2. Adrian Roselli, WCAG3 Contrast as of April 2026: https://adrianroselli.com/2026/04/wcag3-contrast-as-of-april-2026.html
3. Apple HIG, Materials (Liquid Glass; Änderungen 9. Sep 2025): https://developer.apple.com/design/human-interface-guidelines/materials
4. Apple HIG, Color (nur über Spiegelung gelesen, nicht geprüft gegen Original): https://unpkg.com/apple-hig-mcp@1.1.3/content/color.md
5. Creative Review, Cloud Dancer Pantone 2026: https://www.creativereview.co.uk/pantone-colour-of-the-year-2026-cloud-dancer/
6. NN/g, Banner Blindness: Old and New Findings: https://www.nngroup.com/articles/banner-blindness-old-and-new-findings/
7. Wolfe & Horowitz (2004), What attributes guide the deployment of visual attention: https://search.bwh.harvard.edu/new/pubs/WolfeHorowitzNRN04.pdf
8. NN/g, The 3 Response Time Limits: https://www.nngroup.com/videos/3-response-time-limits-interaction-design/
9. Sajjacholapunt & Ball (2014), Frontiers in Psychology (Banner, Gesichter; kein Test von Animation/Farbe): https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2014.00166/full
10. Flutter API, MediaQueryData.disableAnimations: https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
11. Effect of website colour saturation on trustworthiness and visual appeal (IADIS): https://iadisportal.org/digital-library/effect-of-website-colour-saturation-on-trustworthiness-and-visual-appeal-impressions
12. While & Sarvghad, Dark Mode or Light Mode? (arXiv 2409.10841): https://arxiv.org/html/2409.10841v1
13. Wikipedia, Aesthetic-usability effect (Übersicht, Zweitquelle): https://en.wikipedia.org/wiki/Aesthetic%E2%80%93usability_effect
14. Silvennoinen, Vogel & Kujala (2014), Journal of Usability Studies 10(1): https://uxpajournal.org/wp-content/uploads/sites/7/pdf/JUS_Silvennoinen_Nov2014.pdf
15. W3C, Understanding SC 1.4.11 Non-text Contrast (WCAG 2.1): https://w3c.github.io/wcag21/understanding/non-text-contrast
16. a11ybot, 2.3.3 Animation from Interactions (Zweitquelle): https://a11ybot.pages.dev/learn/2-3-3-animation-from-interactions/
17. W3C, Understanding SC 2.3.1 Three Flashes: https://w3c.github.io/wcag21/understanding/three-flashes-or-below-threshold.html
18. WGSN/Coloro, Colour of the Year 2027 Luminous Blue: https://www.wgsn.com/en/wgsn/press/press-releases/wgsn-and-coloro-reveal-colour-year-2027-luminous-blue-and-s-s-27-key
19. Lovart-Blog, Color Trends 2027 (Zweitquelle, Firmenblog): https://www.lovart.ai/blog/color-typography-branding-trends-2027
20. Android Developers, Color for mobile design: https://developer.android.com/design/ui/mobile/guides/styles/color
21. Linear, How we redesigned the Linear UI: https://linear.app/now/how-we-redesigned-the-linear-ui
22. Simons & Rensink (2005), Change blindness: past, present, and future: https://www.cs.ubc.ca/~rensink/publications/download/S&R-TICS-05a.pdf
