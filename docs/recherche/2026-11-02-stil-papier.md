# Stil „Papier“ für eine Rechnungs-App (Bon scannen, Posten zuordnen)

Stand: 2026-11-02. Nur lesend recherchiert (keine Uploads, keine POSTs). Quellen mit Nummer [n] am Ende.
„Vorschlag“ = meine Folgerung, kein Beleg. „nicht geprüft“ = nicht gelesen oder nicht belegt.

## Kurzfassung

1. Papier-Gefühl kommt bei Paper (FiftyThree) vor allem aus Tinte, Bewegung und Raum, kaum aus Textur [3].
2. Skeuomorphie scheitert, wenn sie nur dekoriert und nichts leistet (Notes als Notizblock) [12][21]. Papier hier nur, wo es etwas erklärt: Bon, Zettel, Raster.
3. Material 1 liefert die Grundregel: Schatten entstehen aus relativer Höhe, nie durch Einfärben [1]. Material „biegt und faltet nie“ [1]; genau das ergänzt Papier (Zacken, Knick, Rollung).
4. Textur: prozedural per Fragment-Shader ist möglich (fBm: Oktaven, Lacunarity 2, Gain 0,5) [2][8]. Vorschlag: einmal in ein Bild backen (`Picture.toImageSync` ist dokumentiert [2]) und wiederverwenden.
5. Papierkorn ist statisch. Das vorhandene `grain.frag` ist Filmkorn mit 24 Bildern/s [27]; für Papier nicht verwenden.
6. Zackenkante des Bons: ein `Path` mit Zickzack genügt [15]. Kein Shader nötig.
7. Thermopapier-Eigenheiten, die belegt sind: Schrift verliert Kontrast durch Licht, Wärme, Feuchte, Öle [4][17]. Rollkrümmung: nicht geprüft.
8. Schrift: Monospace für Bon (Courier Prime, OFL [7]); Serife für Seiten (Newsreader, OFL 1.1 [14]); Handschrift nur als Akzent (Caveat, OFL 1.1 [13]).
9. Tinte: Riso-Tinten sind transparent und überdrucken; Passerfehler sind normal; mehrfarbige Textzeilen sind riskant [9]. Vorschlag: nur Stempel/Akzente bekommen den Riso-Versatz, nie Fließtext.
10. Dunkelmodus: Farben nicht invertieren [19]; dunkles Grau statt Schwarz, Elevation über hellere Fläche statt Schatten [6]. Nutzer wollen dunkle Seite und Text-Inversion, aber Bilder/Export unverändert [5].
11. Vorschlag: Seite wird „Kohlepapier“ (warm dunkelgrau). Der Bon bleibt ein gedimmtes helles Papier, weil er ein Dokument ist, kein Hintergrund.
12. Bewegung: Blättern/Abreißen/Ablegen kurz und zweckgebunden. Page Curl lieben viele; Apple bot nach Protest Slide/Curl/Keine an [20]. Also Einstellung plus Zwilling.
13. „Animationen entfernen“: `disableAnimations` (nur Android) und `AccessibilityFeatures.reduceMotion` (iOS) beide abfragen [23].
14. Kontrast hat Vorrang vor Optik: Text ≥ 4,5:1, großer Text ≥ 3:1 [24]. Alle Vorschlagsfarben unten sind gerechnet.
15. Größtes Risiko: Textur unter Text senkt Lesbarkeit (Wirkung auf WCAG bei Textur: nicht geprüft [24]). Textur ≤ 4 % Helligkeitsschwankung, Text bleibt scharf.

## 1. Vorbilder und was übertragbar ist

**Paper by FiftyThree.** Kein Menü, Aktionen als Gesten; kein Zurück, Vorwärts-Navigation [3]. Wenige Werkzeuge (5 Pinsel, 9 Farben), Beschränkung wirkt befreiend [3]. Werkzeuge nach Tätigkeit benannt (Sketch/Write), nicht nach Material [3]. Tinte brauchte Monate Feinschliff; Navigation wurde als Kurzfilm entworfen und in OpenGL mit 3D-Ebenen, Licht und Schatten gebaut [3]. Verworfen: Papiersorten, die das Tintenverhalten ändern („Tinte + Papier = ???“) [3]. Der Text sagt wenig zu Papiertextur [3].
Übertragbar: Wenige Zustände, Papier ändert nie das Verhalten (nur Optik, Vorschlag), Gesten haben Zwilling (Familienregel). Tinte/Animation sorgfältig tunen.

**Material Design 1 („Material“).** Material ist fest, undurchdringlich, überall 1 dp dick; Inhalt addiert keine Dicke [1]. Schatten zeigen relative Höhe (z) und entstehen natürlich daraus [1]. Material „biegt und faltet nie“, ändert Größe nur in der Ebene [1]. Die Metapher „Papier und Tinte“ steht auf dieser Seite nicht (nicht geprüft).
Übertragbar: Ebenenmodell (Tisch, Blatt, Zettel, Stempel), konsistente Schatten aus Höhe. Nicht übertragbar: Starrheit; Papier darf sich krümmen und knicken.

**Apple Notes/Bücher (Papier-Ära).** Skeuomorphie gab Orientierung, Wertgefühl, Tiefe [12]. Sie scheiterte, wo Dekor ohne Funktion war: Notes sah aus wie Block und Leder, war aber Textdatei; Kalender mit Spirale, Game Center mit Filz [12]. Skeuomorphe versagen, wenn sie Optik ohne Nutzen kopieren oder die Grenzen des alten Mediums übernehmen [21].
Bücher: Seitenumschlag (Curl) war „beautiful user-controllable animation“; ersetzt durch Karten-Wischen, nach Kritik in iOS 16.4 wieder da mit Slide/Curl/Keine [20]. Themen ändern nur Hintergrund und Textfarbe: Normal weiß, Sepia gelblich, Nacht schwarz/weiß [18].
Übertragbar: Papier nur mit Funktion; Animation wählbar; Themen als reine Farbwechsel.

**Field Notes / Moleskine.** Field Notes erscheint u. a. als „Original Kraft“ (Raster, Liniert, Blanko) und „Pitch Black“ (nur Händlerlisten gesehen). Maße, Rasterfarben, Papiergewicht: nicht geprüft. Moleskine: nicht geprüft.
Vorschlag: Kraft als Akzentfläche (Ablage/Deckel), Raster als dezente Struktur.

**Notability / GoodNotes.** Suche lieferte nur Vorlagen-Seiten Dritter, keine Herstellerangaben: nicht geprüft. Belegt aus GoodNotes-Forum: meistgewünschte Funktion „echter Dunkelmodus“ (1.160 Stimmen); Seiten bleiben weiß, wenn nur die Oberfläche dunkel wird [5].

**Riso.** Tinten sind transparent und mischen sich; Druckreihenfolge ändert das Ergebnis [9]. Farben passen selten genau übereinander; Gestaltung muss Versatz vertragen; mehrfarbiger Text wird unleserlich [9]. Große 100-%-Flächen werden auf 85 % reduziert [9]. Körnung/Halbton: auf dieser Seite nicht behandelt (nicht geprüft).
Vorschlag: Multiply-Überdruck und 0,5–1 dp Versatz nur für Stempel und Akzentflächen.

**Letterpress.** Eingedrückter Text = zwei Schatten ohne Weichzeichnung, 1 px: dunkel oben, hell unten; Text dunkler als Grund; nur sparsam, da es Lesbarkeit mindern kann [11]. Vorschlag: nur für Überschriften und Stempelmarken.

## 2. Glaubwürdiges Papier in Echtzeit

**Fasern und Körnung.** fBm summiert Rauschschichten: Oktaven, Lacunarity (Frequenz ×2), Gain (Amplitude ×0,5) [8]. Flutter-Shader: GLSL `.frag` in `pubspec.yaml`, `FragmentProgram.fromAsset`, `FlutterFragCoord()`, Farben vormultipliziert; nur `sampler2D`; Kachelmodus Standard `clamp`, andere im Shader nachbauen [2]. Skia: Laden teuer, `FragmentProgram` vorab laden; `FragmentShader`-Objekte wiederverwenden [2].
Vorschlag (nicht geprüft am Gerät): 1) Prozedural mit 3–4 Oktaven einmalig in ein Bild backen (`Scene/Picture.toImageSync` [2]) und als `ImageShader` kacheln; 2) alternativ kleine Kachel-PNG (256 px) im Repo. Beides vor Einsatz auf S23 und einem schwachen Gerät messen. Der Ratgeber dev.to nennt Regeln („wenig Verzweigungen“, 4–5 ms Budget) ohne Beleg [16]; nicht übernehmen.
Impeller kompiliert eigene Shader des Engines vorab; zu eigenen Fragment-Shadern sagt die FAQ nichts [22].
Hinweis aus eigenem Code: `highp` und kleine Hash-Eingaben, sonst Fehler auf dem S23 [27].

**Leichte Unebenheit, Licht, Schatten.** Vorschlag: eine Lichtquelle oben links, Schatten fallen nach unten rechts (konsistent mit [1], Schatten aus Höhe). Kontaktschatten (scharf, klein) + weicher Umgebungsschatten, zwei Schichten. Gewellte Kanten, Falten, Knicke: keine belastbare Quelle gefunden (nicht geprüft). Vorschlag: Knick als Linie mit Hell/Dunkel-Verlauf (zwei Streifen), 1 Knick pro Bon, nur wo Inhalt ihn verträgt.

**Zackenkante (Abriss).** Path: oben links beginnen, rechts runter, unten in Schritten (z. B. 20) zwei Punkte je Schritt (10 hoch, dann zurück auf Kante), schließen [15]. Das Beispiel dort hat Codefehler (Paint-Zuweisung) [15]. Vorschlag: Zähne mit leichter Zufallsabweichung (fester Seed pro Bon), sonst wirkt es wie Schere.

**Durchscheinen.** Keine Quelle, nicht geprüft. Vorschlag: weglassen (Text unter Text kostet Kontrast).

**Thermopapier.** Aufbau: Leukofarbstoff plus Entwickler (Phenole, oft BPA), Sensibilisator, Stabilisator [17]. Verblassen durch UV, Wasser, Öle/Fette, Weichmacher; Hitze und Feuchte lassen Farbstoff zurückfallen; Kaffeetasse oder Fingernagel hinterlassen Spuren [17]. Haltbar etwa 6 Monate bis 2 Jahre bei guter Lagerung; Hitze gibt dunkle Flecken, Licht senkt Kontrast [4]. Farbe des Verblassens (grau/braun): Quellen widersprechen sich nicht, beschreiben es nicht (nicht geprüft). Rollkrümmung: nicht belegt.
Vorschlag: „Verblassen“ nur als Zustand für alte Bons (Kontrast der Schrift sinkt bis ≥ 4,5:1 Grenze, nie darunter), plus Hinweis „Original verblasst, Foto ist besser“ ist Inhalt, kein Effekt.

## 3. Typografie und Tinte

Alle Schriften sind **Vorschläge**; Lizenz nur dort „belegt“, wo gelesen. Im Repo liegen bereits Geist/Inter/GeistMono mit OFL-Dateien [27].

- Bon: **Courier Prime**, SIL OFL, Alan Dague-Greene [7]. Quittungsdrucker nutzen einfache Monospace-Schriften (Font A groß/fett für Summe, Font B klein für Posten); OCR-B gilt als lesbarer [10]. Monospace richtet Preise bündig aus [10].
- Alternative Bon-Schrift: IBM Plex Mono (OFL vermutet, nicht geprüft), Geist Mono (im Repo, OFL [27]).
- Seiten/Überschriften: **Newsreader**, OFL 1.1, Production Type, Variable Font, für Bildschirmlesen gedacht [14].
- Handschrift-Akzent: **Caveat**, OFL 1.1, Pablo Impallari; Buchstabenvarianten wirken natürlich [13]. Nur für kurze Namen/Notizen, nie für Beträge.
- Schreibmaschine: **Special Elite** wird als „ASL“ (Apache) geführt, Autor Brian J. Bonislawsky [26]; Lizenztext nicht geprüft. Nur nach Prüfung; Courier Prime reicht.
- Oberfläche (Knöpfe, Listen): bei Geist/Inter bleiben (Familie, Lesbarkeit).

**Tinte.** Vorschlag: Text als reine Fläche, Ausblutung nur an Stempel und Überschrift (Schatten 0,3 dp, Alpha 0,25). Letterpress nur für Überschriften [11]. Raster/Linien (Karo, liniert) als Struktur: 1 px Linie, Alpha 0,10–0,14, Abstand 20–24 dp (Vorschlag).

## 4. Bewegung

Belegt: Paper nutzte Bewegung für Raum und Orientierung (Pinch statt Zurück) [3]; Material: Z-Bewegung folgt aus Nutzereingabe [1]; Seitenumschlag lieben viele, aber wählbar [20]; Skeuomorphie darf Funktion nicht verdecken [12][21]. `disableAnimations` = Android „Animationen entfernen“; iOS über `reduceMotion` [23] (siehe auch [28]).

Vorschläge (alle nicht geprüft am Gerät):
- Ablegen: Blatt sinkt 2 dp, Schatten wird enger, 160 ms ease-out.
- Stapeln: Versatz je Blatt ±1° und 2 dp, Rotation fest pro Beleg (Seed), keine Dauerbewegung.
- Abreißen (Bon vom Streifen): Zug nach unten folgt dem Finger, Einrasten ab 40 % der Höhe, sonst Rückfedern. Zwilling: Knopf „Bon abtrennen“.
- Blättern: Slide als Standard, Curl wählbar, Keine möglich [20].
- Mit „Animationen entfernen“: Wechsel per Überblendung 0–80 ms, kein Rotieren, kein Fallen.
- Keine Partikel, kein Papierrascheln, kein Dauerwackeln.

## 5. Dunkelmodus für Papier

Belegt: Material empfiehlt dunkles Grau statt Schwarz (#121212), gedämpfte Farben, Elevation durch hellere Flächen statt Schatten, Text nie reinweiß, Textdeckkraft 87/60/38 % [6]. Apple: nicht invertieren; Elevation durch Farbe; Kontrast ≥ 4,5:1 [19]. GoodNotes-Nutzer: Seite und Text dunkel, Bilder/Export unverändert, Wahl pro Notizbuch und global [5]. Bücher-Nacht: Hintergrund schwarz, Text weiß, nur diese zwei Farben ändern sich [18]. Bear führt viele dunkle Themen (u. a. Dark Graphite, Dark Notes) [25]; Detailfarben: nicht geprüft.

Vorschlag:
- **Kohlepapier**: Seite warm dunkelgrau (#211F1C) auf Grund #151412; Kreide-Text #E8E3D6.
- Schatten fast unsichtbar; Höhe über +4 bis +6 % hellere Fläche und 1 px Oberkante (Hell) [6][19].
- **Bon im Dunkeln**: bleibt helles Papier, gedimmt (#D9D4C7, Tinte #1E1C19). Begründung: Dokument/Foto-Treue [5]. Option „Bon invertieren“ in Einstellungen (Vorschlag).
- Kraftpapier (#8A6A45 hell / #3A2E22 dunkel, Vorschlag) nur für Ablage/Deckel, nicht für Fließtext.

## 6. Token-Vorschläge

Kontrastwerte gerechnet (WCAG-Formel, Python); Ziel 4,5:1 normal, 3:1 groß [24].

### Farben

| Token | Hell | Dunkel | Kontrast / Hinweis |
|---|---|---|---|
| desk (Tischgrund) | #E9E4D8 | #151412 | Grund |
| paper (Seite) | #F6F2E7 | #211F1C | |
| paper-alt (Raster-Seite) | #EFEADD | #27241F | |
| receipt (Bon) | #F3F1EC | #D9D4C7 | gedimmt im Dunkeln |
| note (Notizzettel) | #F3E6B0 | #2E2A22 | |
| ink | #23211E | #E8E3D6 | 14,36 auf paper / 12,83 |
| ink-muted | #5A564E | #A8A194 | 6,53 / 6,41 |
| ink-thermal (Bonschrift) | #34322F | #1E1C19 | 11,32 auf receipt / 11,49 |
| ink-faded (alter Bon, Untergrenze) | #6E6A63 | #55514A | 4,76 / 5,33 |
| stamp (Stempelrot) | #B83A22 | #E8836B | 5,12 / 6,18 |
| blue-ink | #2B4C8C | #8FB0E8 | 7,46 / 7,47 |
| hand (Notiz auf Zettel) | #3B2F1A | #EDE3C4 | 10,42 / 11,14 |
| grid-line | #23211E @ 12 % | #E8E3D6 @ 10 % | dekorativ |
| kraft | #8A6A45 | #3A2E22 | nur Fläche (Kontrast nicht gerechnet) |

Hinweis: Bon hell gegen Tisch nur 1,12:1; die Trennung kommt aus dem Schatten, nicht aus der Farbe. Der Bon-Rand braucht daher zusätzlich eine Haarlinie (Vorschlag). Der Bestandswert `FasanAccent.signal` hell (Grund #F4F2EE, Text #1B1B1A) bleibt kompatibel [27].

### Schriften

| Rolle | Schrift | Lizenz |
|---|---|---|
| Bon | Courier Prime | SIL OFL [7] |
| Bon alternativ | Geist Mono (im Repo) | OFL [27] |
| Seiten/Titel | Newsreader (Variable) | SIL OFL 1.1 [14] |
| Handschrift-Akzent | Caveat | SIL OFL 1.1 [13] |
| Oberfläche | Geist / Inter (im Repo) | OFL [27] |
| Nur nach Prüfung | Special Elite | „ASL“ gemeldet [26], nicht geprüft |

Bon-Größen (Vorschlag): Posten 15 sp, Summe 20 sp fett, Zeilenhöhe 1,35; Mindest-Tippfläche 48 dp (Profil Einfach 60 dp, laut Projektregeln).

### Schatten (Vorschlag, Licht oben links)

| Stufe | Hell (Farbe, Offset, Blur) | Dunkel |
|---|---|---|
| Kontakt (Zettel auf Seite) | #28200F @ 0,18, (0,1), 1 | #000 @ 0,40, (0,1), 1 |
| Aufliegend (Seite, Bon) | #28200F @ 0,14, (1,3), 8 | #000 @ 0,35, (0,2), 6 + Fläche +4 % |
| Abgehoben (gezogen) | #28200F @ 0,18, (2,8), 20 | #000 @ 0,45, (0,6), 14 + Fläche +6 % |

Umrechnung `blurRadius` ↔ Sigma: nicht geprüft; vor Einsatz in der Flutter-API nachlesen.

### Textur

| Parameter | Wert | Status |
|---|---|---|
| Methode | fBm, 3–4 Oktaven, Lacunarity 2, Gain 0,5 [8], einmal gebacken | Vorschlag |
| Faser-Skala | 0,6–1,2 dp je Zelle, leicht gestreckt (Faden) | nicht geprüft |
| Stärke | ±2–4 % Helligkeit (hell), ±1,5–3 % (dunkel) | Vorschlag |
| Zeitlich | statisch, kein `uTime` | Vorschlag |
| Kachel | 256–512 px, Wiederholung per `ImageShader` | Kachelmodus im Shader nötig [2] |
| Aus | bei Energiesparmodus und „Transparenz reduzieren“: einfarbig | Vorschlag, passend zu `reduceTransparency` [27] |
| Zackenkante | Zahnbreite 10–16 dp, Tiefe 3–6 dp, ±30 % Zufall, fester Seed | Vorschlag |
| Rollkrümmung | 0–1,5° Schrägverlauf Schatten oben/unten | nicht geprüft |

## 7. Fünf Bausteine

1. **BonStreifen**: abgerissener Thermopapier-Streifen. Zackenkante oben/unten (Path [15]), Courier Prime, Summe fett, Perforations-Strichlinie vor der Summe, Zustand „verblasst“ (Kontrast sinkt bis `ink-faded`). Streifen darf länger als der Bildschirm sein (Scroll). Dunkel: gedimmtes Papier [5]. Abtrennen per Zug oder Knopf.
2. **PostenZettel**: Posten als Notizzettel (`note`), Ecke 2 dp, Kontaktschatten, Name der Person in Caveat (sparsam), Betrag in Mono. Zuordnen = Zettel auf Personenkarte ablegen (Ablege-Bewegung); Zwilling: Auswahlliste. Zettelversatz ±1° fester Seed.
3. **RasterBlatt**: Seite `paper-alt` mit Karo/Liniert (Alpha 0,10–0,14) als Struktur für Listen und Abrechnung; Zeilen fluchten am Raster. Newsreader-Titel. Raster endet am Rand ohne Textur darunter.
4. **StempelMarke**: „Bezahlt“, „Offen“, „Geteilt“ als Stempel (`stamp`, Riso-Überdruck mit 0,5–1 dp Versatz [9], Letterpress-Kante [11]). Maximal 1 Stempel pro Karte. Text bleibt als Semantik-Label lesbar.
5. **ArchivStapel**: Ablage abgeschlossener Rechnungen als Stapel mit festem Versatz (±1°), Kraft-Deckel. Blättern per Slide (Curl wählbar, Keine möglich [20]). „Animationen entfernen“: Überblendung [23].

## 8. Offene Punkte (nicht geprüft)

- Messung Textur-Backen und Shader auf S23 und schwachem Gerät (Impeller-FAQ sagt zu Fragment-Shadern nichts [22]).
- Farbe/Verlauf echter Thermopapier-Alterung (grau/braun), Rollkrümmung, Falten, Durchscheinen.
- Lizenz Special Elite, IBM Plex Mono; Maße und Farben bei Field Notes, Moleskine, Notability, GoodNotes.
- Wirkung von Textur unter Text auf WCAG 1.4.3 (Quelle [24] äußert sich nicht).
- `BoxShadow`-Sigma-Umrechnung.
- Nutzertest: Wirkt Papier-Look ruhig und lesbar, oder kitschig [12]?

## Quellen

1. Material Design (M1), Material properties: https://m1.material.io/material-design/material-properties.html
2. Flutter, Writing and using fragment shaders: https://docs.flutter.dev/ui/design/graphics/fragment-shaders
3. „Paper at 10“ (FiftyThree-Rückblick): https://notbor.ing/words/paper-at-10
4. POSPaper, Does thermal paper fade: https://www.pospaper.com/blogs/news/does-thermal-paper-fade
5. GoodNotes Feedback, True dark mode / In-app dark mode for paper: https://feedback.goodnotes.com/forums/191274-customer-suggestions-for-goodnotes/suggestions/42481105-in-app-dark-mode-for-paper-and-texts
6. UX Planet, 8 Tips for Dark Theme Design (zitiert Material): https://uxplanet.org/8-tips-for-dark-theme-design-8dfc2f8f7ab6
7. Courier Prime Read-me (OFL, Alan Dague-Greene): https://cdn.jsdelivr.net/npm/afterwriting@1.17.3/js/fonts/source/Courier-Prime/Read-me.txt
8. The Book of Shaders, Kapitel 13 (fBm), Spiegel: https://git.blob42.xyz/Archives/thebookofshaders/src/commit/8d22c33ca0ccfd1062fc36729df8978672ae38f6/13
9. MICA, Risograph file prep: https://www.mica.edu/campus-life-and-resources/places-and-spaces/maker-spaces-fabrication-studios/printmaking-studio/risograph-file-prep/
10. HPRT, Receipt Font Guide: https://www.hprt.com/Product/POS-PRINTERS/Receipt-Font-Guide.html
11. Smashing Magazine, Simulating the Letterpress: https://www.smashingmagazine.com/2012/07/letterpress-effect-fireworks-css/
12. Macworld, Why I'll miss skeuomorphism in iOS: https://www.macworld.com/article/221261/why-ill-miss-skeuomorphism-in-ios.html
13. Fontsource, Caveat (OFL 1.1): https://fontsource.org/fonts/caveat/about
14. GitHub, productiontype/Newsreader (OFL 1.1): https://www.github.com/productiontype/Newsreader
15. Gurubase, Torn receipt effect in Flutter: https://gurubase.io/g/flutter/create-torn-receipt-effect-flutter
16. dev.to, Impeller custom shaders (ohne Belege, nur zur Abgrenzung): https://dev.to/devin-rosario/mastering-impeller-custom-shaders-for-120fps-flutter-apps-2020
17. Wikipedia, Thermal paper: https://en.wikipedia.org/wiki/Thermal_paper
18. Macworld, iBooks Night-Thema: https://www.macworld.com/article/215602/apple_updates_ibooks_app_with_new_fonts_and_a_night_reading_theme.html
19. Prototypr, Designing a dark mode for your iOS app: https://blog.prototypr.io/designing-a-dark-mode-for-your-ios-app-the-ultimate-guide-6b043303b941
20. Basic Apple Guy, Build a Better Books: https://basicappleguy.com/basicappleblog/build-a-better-books
21. Ricardo Pinto, The trouble with skeuomorphs: https://www.ricardopinto.com/?p=5483
22. Flutter Engine, Impeller FAQ: https://github.com/flutter/engine/blob/main/impeller/docs/faq.md
23. Flutter API, MediaQueryData.disableAnimations: https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
24. DAISY Knowledge Base, WCAG Contrast (Minimum): https://kb.daisy.org/publishing/docs/wcag/contrast-minimum.html
25. Bear, About free and Pro themes: https://bear.app/faq/about-free-and-pro-themes-in-bear/
26. Fedora Wiki, Special Elite Fonts: https://fedoraproject.org/wiki/Special_Elite_Fonts
27. Eigener Code: `/home/claude/fasan_ui/shaders/grain.frag`, `/home/claude/fasan_ui/lib/src/theme.dart`, `/home/claude/fasan_ui/fonts/`
28. Eigene Recherche: `/home/claude/fasan_ui/docs/recherche/2026-11-02-farbe-verlauf-aufmerksamkeit.md`
