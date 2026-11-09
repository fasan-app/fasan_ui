# Lebendig, organisch, reaktiv: Warten und Hinweise (Bon-App)

Stand: 2026-11-02. Nur lesend recherchiert (Beschluss 02.11.), nichts gesendet.
Kennzeichen: **[geprüft]** = Seite gelesen, Aussage dort belegt. **[Sekundär]** = nur über Dritte/Port/Blog. **[nicht geprüft]** = nicht belegt. **[Vorschlag]** = eigener Wert, im Test zu prüfen.

## Kurzfassung

1. Scan dauert 20–50 s. Das liegt über Nielsens 10-s-Grenze. Dann braucht es Fortschritt mit Schritten, nicht nur einen Spinner. [geprüft: NN/g]
2. Zeige die Arbeit: benannte Stufen („Spalten lesen“) und sichtbare Ergebnisse. Das hebt den wahrgenommenen Wert (Labor Illusion). Zahlen aus Buell & Norton sind nicht geprüft; nur das Abstract. [geprüft: Abstract]
3. Fortschrittsbalken: lieber am Ende schneller werden. Pausen am Ende und Pulsieren des Balkens wirken länger. [geprüft: Harrison 2007, 5,5-s-Test]
4. Weil die Dauer schwankt: Schrittzähler („Schritt 3 von 6“) statt Prozent-Versprechen. [geprüft: NN/g]
5. Hinweise, auf die die App wartet: ein einmaliger Impuls plus ein stehendes Zeichen (Ring/Punkt) plus Text. Kein Dauer-Pulsen. [WCAG 2.2.2 geprüft; Rest Vorschlag]
6. Bewegung > 5 s, die von selbst startet, braucht Pause/Stopp. Ausnahme: wesentliche Bewegung. Interaktionsbewegung muss abschaltbar sein (AAA). [geprüft: W3C]
7. Flutter: `MediaQuery.disableAnimations` ist auf Android die Einstellung „Animationen entfernen“. Auf iOS ist es ein anderes Flag. [geprüft: api.flutter.dev]
8. Federn statt Kurven: Geschwindigkeit der Geste übernehmen, Bewegung unterbrechbar halten. Apple-Zahlen (WWDC18 803) nur sekundär. [Sekundär]
9. Haptik: kurz, pro Ereignis ein festes Muster, nie als einziger Kanal, abschaltbar. [geprüft: Apple HIG]
10. Offene Lücken: NN/g Skelett-Bildschirme (Seite nicht ladbar), Banner-Blindheit/Coach Marks (nur Titel), Harrison 2010 Zahlen, WWDC18 Primärquelle.

## 1. Psychologie des Wartens

- **Schwellen (Nielsen).** 0,1 s: nur Ergebnis zeigen. 1 s: Gedankenfluss bleibt, danach Hinweis „Computer arbeitet“. 10 s: Aufmerksamkeit hält nicht; Rückmeldung, wann es fertig ist; Prozent-Anzeige ab etwa 10 s; ein klarer Weg zum Abbrechen. [geprüft] https://www.nngroup.com/articles/response-times-3-important-limits/
- **Zuordnung Anzeige zu Dauer (NN/g 2014).** Fortschrittsanzeige bei allem über ca. 1 s. Endlos-Animation nur für ca. 2–10 s. Prozent-Anzeige ab 10 s oder mehr. Keine Endlos-Animation über 10 s. Je größer die Streuung der Schätzung, desto früher die aufwendigere Anzeige. [geprüft] https://www.nngroup.com/articles/progress-indicators/
- **Tipps dort:** langsam starten, am Ende schneller werden; grobe Zeitschätzung mit Reserve (früher fertig ist eine nette Überraschung); Schrittzähler bei Reihen („3 von 50“); statische „Lädt…“-Texte ersetzen; zeigen, dass der erste Klick ankam. [geprüft, gleiche Seite]
- **Studie dort:** Nutzer mit Endlos-Balken waren zufriedener und warteten im Mittel dreimal länger als ohne Anzeige (Universität Nebraska-Lincoln, wie von NN/g berichtet). Originalstudie nicht gelesen. [Sekundär]
- **Myers 1985.** Version mit Prozent-Anzeige wurde signifikant besser bewertet (p < 0,0006); 86,1 % mochten Anzeigen. Anfänger sehen, dass der Befehl ankam; ein stehender Balken verrät einen Absturz. [geprüft] https://graphicsinterface.org/wp-content/uploads/gi1985-24.pdf
- **Harrison et al. 2007** (CHI, 9 Fortschrittsfunktionen, je 5,5 s, 22 Personen; längere Dauern nicht getestet). Beschleunigung zum Ende wirkte schneller und war klar bevorzugt. Späte Pause wirkte langsamer. Wellig/pulsierend wirkte langsamer als linear. Keine Prozentwerte im Paper. [geprüft] https://chrisharrison.net/projects/progressbars/ProgBarHarrison.pdf
- **Harrison et al. 2010** (CHI, visuelle Balkenstile, Pulsen/Wellen im Balken): Seite sagt nur, dass Stile verglichen wurden. Ergebnisse und Zahlen [nicht geprüft]. https://chrisharrison.net/index.php/Research/ProgressBars2
- **Labor Illusion (Buell & Norton 2011, Management Science 57(9)).** Fünf Experimente (Reisen, Dating). Wenn eine Seite zeigt, dass sie arbeitet, ziehen Menschen u. U. eine langsamere Seite mit gleichem Ergebnis vor. Wirkung läuft über wahrgenommene Mühe und Gegenseitigkeit; Grenzfälle werden untersucht. [geprüft: nur Abstract] https://econpapers.repec.org/RePEc:inm:ormnsc:v:57:y:2011:i:9:p:1564-1579 — Wartezeiten, Effektgrößen und Grenzfälle im Detail [nicht geprüft].
- **Folgerung für uns:** Die Labor Illusion rechtfertigt keine künstliche Verzögerung. Sie rechtfertigt, die echte Arbeit sichtbar zu machen. Eine Seite nennt den „Instant Trap“ (zu schnelles Ergebnis wirkt unglaubwürdig), aber ohne Quelle [Sekundär, nicht belegt] https://vectree.io/c/the-labor-illusion-and-the-psychological-perception-of-time-in-ui-loading-states. Wir bremsen nie künstlich (ethische Linie, Vorschlag).
- **Buell, Kim, Tsay (HBS WP 14-115):** Prozess sichtbar machen steigerte in Gastro-Feldstudien die berichtete Qualität (22,2 %) und senkte Durchlaufzeit (19,2 %). Anderer Kontext (Essen, Personal); nur als Hinweis auf Vertrauen durch Sichtbarkeit. [geprüft] https://ideas.repec.org/p/hbs/wpaper/14-115.html
- **Skelett-Bildschirme vs. Spinner (NN/g):** Seite nicht ladbar, daher [nicht geprüft]. **Material 3 Loading Indicator:** für Vorgänge unter ca. 5 s; für längere oder messbare Vorgänge Fortschrittsanzeige, die von unbestimmt auf bestimmt wechseln kann. Kontrast ≥ 3:1, Beschreibung für Screenreader. [Sekundär: Spiegel der Android-Doku] https://gitea.com/784622644/material-components-android/src/branch/master/docs/components/LoadingIndicator.md
- **Für uns:** Ein Skelett passt nur, wenn das Layout vorher bekannt ist. Beim Bon ist es das nicht. Das Foto selbst ist die „Bühne“; es braucht keinen Platzhalter. [Vorschlag]

## 2. Muster für sichtbares Arbeiten

- **Apple Live Text/VisionKit:** erkannte Elemente werden hervorgehoben, wenn man die Live-Text-Taste antippt; Tippen auf Text öffnet passende Aktionen (kopieren, anrufen usw.). Die Hervorhebung ist Nutzer-gesteuert, keine Dauer-Animation. [geprüft: Apple-Doku] https://developer.apple.com/tutorials/data/documentation/visionkit/enabling-live-text-interactions-with-images.md
- **Notizen-Scanner, Google Lens, Banking-Apps (Scan-Linie, Zeilen tauchen auf, Zahlen zählen hoch):** Suchergebnisse lieferten nur Anleitungen, keine Gestaltungsbelege. [nicht geprüft] Die Muster in Abschnitt „Vorschläge“ sind deshalb eigene Entwürfe auf Basis der geprüften Regeln.
- **Microinteractions (Saffer):** Auslöser, Regeln, Rückmeldung, Schleifen/Modi. Rückmeldung bestätigt, dass die Aktion ankam. Schleifen bestimmen, ob etwas wiederholt wird. [Sekundär: Zusammenfassung] https://blog.prototypr.io/the-4-components-of-a-microinteraction-836732173c7c Buch selbst nicht gelesen.
- **Apple HIG Motion:** Bewegung mit Absicht; knappe, präzise Rückmeldung wirkt leichter; Bewegung bei häufigen Interaktionen meiden; Nutzer dürfen Bewegung abbrechen. [geprüft] https://developer.apple.com/design/human-interface-guidelines/motion.md

## 3. Zustände, auf die die App wartet

- **Bewegung nie als einziger Kanal.** Apple: Bewegung optional halten; mit Haptik/Ton ergänzen. [geprüft: HIG Motion]
- **WCAG 2.2.2 Pausieren, Stoppen, Ausblenden (A).** Bewegung, die automatisch startet, länger als 5 s läuft und neben anderem Inhalt steht, braucht Pause/Stopp/Ausblenden. Ausnahme „wesentlich“ (z. B. Preloader als einziger Inhalt). Selbst aktualisierende Inhalte haben keine 5-s-Ausnahme. [geprüft] https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide
  - Folge: Ein Hinweis-Puls darf nicht endlos laufen. Ein Impuls ≤ 5 s oder ein sichtbarer „Ausblenden“-Zwilling.
  - Ob die Scan-Linie als „wesentlich“ gilt: Auslegung, nicht geprüft. Sicher ist: Scan-Linie stoppt bei Fertig/Abbruch und hat eine Tippfläche „Abbrechen“.
- **WCAG 2.3.3 Animation aus Interaktion (AAA).** „Motion animation“ (Position/Größe) durch Interaktion muss abschaltbar sein, außer wesentlich. Farbe/Deckkraft zählen nicht als Bewegung. Techniken: System-„Bewegung reduzieren“ beachten, App-Einstellung. [geprüft] https://w3c.github.io/wcag/understanding/animation-from-interactions.html
  - Folge: Ersatz bei „reduziert“ = Überblenden (Deckkraft/Farbe) statt Verschieben/Skalieren.
- **Flutter:** `MediaQueryData.disableAnimations`: auf Android = „Animationen entfernen“; auf iOS wird es nicht gesetzt, dort `AccessibilityFeatures.reduceMotion`. Eigene Animationen müssen das Flag selbst prüfen. [geprüft] https://api.flutter.dev/flutter/widgets/MediaQueryData/disableAnimations.html
- **Apple (visionOS) warnt vor dauerhaftem Schwingen um ca. 0,2 Hz** (Periode ~5 s) wegen Empfindlichkeit. Gilt dort für Objekte im Raum; auf dem Handy [nicht geprüft], aber ein Hinweis, „Atmen“ nicht im Bereich 4–6 s Periode laufen zu lassen. [geprüft: HIG Motion, visionOS-Teil]
- **Coach Marks, Banner-Blindheit, Wiederholgrenzen:** Suchen lieferten nur Titel (Benway/„Banner blindness“-Literatur, Grundaussage: Nutzer übersehen Dinge, die wie Werbung aussehen oder ständig da sind). Belege und Zahlen [nicht geprüft]. Daher Grenzen unten als [Vorschlag].

## 4. Organische Bewegung

- **Federn statt Kurven.** M3 Expressive: räumliche Bewegung (Position/Größe) darf überschwingen; Effekte (Farbe/Deckkraft) bleiben glatt ohne Überschwingen. Federn behalten bei Unterbrechung die Geschwindigkeit, Kurven rechnen von vorn. [Sekundär: Artikel] https://www.besthub.dev/articles/why-google-s-material-3-update-turns-motion-into-a-theme-it-s-not-about-the-bounce-9436fce4a345
- **M3-Federwerte (Steifigkeit / Dämpfungsverhältnis).** Aus einem inoffiziellen Rust-Port der Tokens, nicht aus Googles Doku: räumlich schnell 1400/0,9, normal 700/0,9, langsam 300/0,9; Effekte schnell 3800/1,0, normal 1600/1,0, langsam 800/1,0; „Expressive“-Räumlich schnell 800/0,6, normal 380/0,8, Druck 380/0,55, langsam 200/0,8. [Sekundär] https://docs.rs/frust-material/0.6.2/src/frust_material/tokens/motion.rs.html Gegen offizielle M3-/Compose-Quelle prüfen, bevor wir sie fest verdrahten.
- **Apple „fluid interfaces“ (WWDC18 803).** Primärseite war nicht abrufbar. Sekundär (Skill-Seite, die „Apple-Werte“ behauptet, ohne Zeitmarke): Verschieben Dämpfung 1,0 / Antwort 0,4 s; Drehung 0,8 / 0,4 s; Schublade 0,8 / 0,3 s. Auch dort: Release-Geschwindigkeit als Start-Geschwindigkeit der Feder, von der aktuell sichtbaren Position starten, Unterbrechung ohne Sprung. [Sekundär, nicht gegen Video geprüft] https://www.ui-skills.com/skills/emilkowalski/apple-design/ — Vor Übernahme das Video/Transkript lesen.
- **Umrechnung Antwort→Steifigkeit** (Masse 1, k = (2π/T)²): T=0,4 s → k≈247; T=0,3 s → k≈439. Eigene Rechnung, Formel-Annahme [nicht geprüft]. Flutter-Konstruktor `SpringDescription.withDampingRatio` [nicht geprüft; Seite nicht abrufbar].
- **Dauer-Faustwerte (Blog, keine Studie genannt):** Handy 200–300 ms, Tablet ca. +30 %, Wearable ca. −30 %; Listenpunkte versetzt um 20–25 ms; Linear nur für Farbe/Deckkraft; Eintritt = Ease-out. [Sekundär] https://uxdesign.cc/the-ultimate-guide-to-proper-use-of-animation-in-ux-10bd98614fa9
- **M3-Dauerstufen (ms):** short 50/100/150/200, medium 250/300/350/400, long 450/500/550/600, extra-long 700–1000. Standard-Kurve (0.2, 0, 0, 1). [Sekundär: Port] https://docs.rs/crate/hydrolysis-m3/latest/source/src/theme/motion/tokens.rs
- **Haptik (Apple HIG):** Muster nur nach dokumentierter Bedeutung; je Ereignis immer dasselbe Muster; zur Animation passend in Stärke und Schärfe; sparsam; kurze Impulse statt Dauer-Vibration; abschaltbar. Muster: Benachrichtigung (Erfolg, Warnung, Fehler), Aufprall (leicht…schwer, weich/starr), Auswahl (Werte ändern sich). [geprüft] https://developer.apple.com/design/human-interface-guidelines/playing-haptics.md
  - Android-Entsprechungen (Konstanten, Mindest-API, Geräteunterschiede) [nicht geprüft]. Vor Einbau developer.android.com lesen (Regel „nicht raten“).

## Vorschläge für die Bon-App (alle [Vorschlag], im Test prüfen)

### A. Scan-Ablauf (20–50 s)

1. **0–1 s:** Foto sofort einfrieren und leicht abdunkeln, Taste „Abbrechen“ sichtbar. Erste Rückmeldung < 100 ms (Nielsen 0,1 s). Haptik: Aufprall „leicht“ beim Start.
2. **Schrittanzeige statt Prozent:** „Schritt 3 von 6: Spalten lesen“. Sechs Stufen: Foto prüfen, entfalten, begradigen, Spalten lesen, Posten prüfen, Summe vergleichen. Grund: Dauer schwankt, NN/g rät dann zu einfacheren Zusagen. Keine Zeitzusage; höchstens „dauert meist unter einer Minute“ (Wert nach Messung auf echten Geräten setzen).
3. **Balken:** Füllung auf Stufen verteilt, keine Pausen vor dem Ende, kein Pulsen im Balken (Harrison 2007). Die letzte Stufe darf schneller füllen. Stehender Balken > 8 s = Text wechselt zu „Das dauert diesmal länger“ (bleibt ehrlich; Wert [Vorschlag]).
4. **Scan-Linie nur dort, wo wirklich gearbeitet wird** (Stufen Entfalten/Begradigen/Spalten): ein Band über dem Foto, 1,4–1,8 s pro Durchlauf, Ease-in-out, Deckkraft 35 %. Sie folgt dem echten Bearbeitungsstand der Stufe (z. B. Zeile, die gerade gelesen wird), nicht einer Zufallsschleife. Wenn kein Fortschritt messbar: Linie ruhen lassen.
5. **Erkannte Zeilen:** Sobald Spalten gelesen sind, erscheinen Zeilen nacheinander mit 30–40 ms Versatz (Blog: 20–25 ms; bei > 20 Zeilen auf 20 ms kürzen, Gesamtdauer ≤ 700 ms), Deckkraft 0→1 mit Effekte-Feder (Steifigkeit 1600, Dämpfung 1,0) plus 8 dp Verschiebung mit räumlicher Feder (700/0,9).
6. **Zahlen zählen hoch:** Summe/Preis von 0 auf Wert in 600–800 ms, Ease-out. Nur beim ersten Erscheinen. Der Endwert steht im Semantik-Label sofort (Screenreader hört nie Zwischenwerte).
7. **Summe vergleichen:** Treffer: Summe wird kurz fett, Haken, Haptik „Erfolg“ (ein Muster, immer gleich). Abweichung: kein Rot-Alarm, sondern Differenz als Zeile „Differenz 2,30 €“ plus ruhiger Hinweis (Abschnitt B).
8. **Abbruch jederzeit,** Fortschritt behalten, wenn möglich. Fertig-Zustand darf nicht auf das Ende einer Animation warten (HIG: Animation abbrechbar).
9. **Reduzierte Bewegung** (`disableAnimations` Android, `reduceMotion` iOS, App-Schalter): keine Scan-Linie; stattdessen Stufen-Text und Balken (Balken füllt weiter, das ist Information); Zeilen erscheinen per Überblenden ohne Versatz; Zahlen springen direkt.
10. **Ton/Haptik:** höchstens zwei Haptik-Ereignisse im ganzen Scan (Start, Ende). Nie pro Zeile.

### B. Zuordnen (Posten zu Personen)

1. **Wartet auf Tippen:** Beim ersten Posten ohne Zuordnung ein einmaliger Impuls auf der Personenleiste (Skalierung 1→1,06→1, räumliche Feder 380/0,8, ca. 600 ms), dazu stehender Text „Tippe auf eine Person“. Der Text ist der sichtbare Zwilling.
2. **Danach stehendes Zeichen statt Bewegung:** nicht zugeordnete Posten behalten einen ruhigen Rand-/Punktmarker (Kontrast ≥ 3:1). Bewegung nur auf Änderung.
3. **Wiederholgrenze:** höchstens 2 Impulse je Bildschirmbesuch (zweiter erst nach 8–10 s ohne Eingabe), danach nie wieder bis zum nächsten Besuch. Gesamtbewegung ≤ 5 s (WCAG 2.2.2). Kein „Atmen“-Dauerloop. Falls später getestet: Periode 2–3 s, Amplitude ≤ 3 %, nach 3 Zyklen stoppen. Banner-Blindheit-Gründe nicht belegt [nicht geprüft].
4. **Tippen auf Person:** Person-Chip drückt sich ein (Druck-Feder 380/0,55 hin, 380/0,8 zurück), Posten „fliegt“ als Marke zur Person: räumliche Feder 700/0,9, ca. 250–350 ms, Start an der Fingerposition. Haptik: Auswahl-Tick.
5. **Ziehen statt Tippen (falls geboten):** beim Loslassen Release-Geschwindigkeit als Start-Geschwindigkeit der Feder übernehmen; Bewegung von aktueller Position aus umlenkbar; Drop-Ziel rastet mit Aufprall „leicht“. Sichtbarer Zwilling: Tippen.
6. **Mehrere Personen am Posten:** Anteile gleiten (Feder 700/0,9) statt zu springen; Summen zählen in ≤ 300 ms um.
7. **Rückgängig:** Snackbar „Rückgängig“ ≥ 5 s sichtbar; Gegenbewegung = Umkehr derselben Feder.
8. **Unterbrechbar:** Jede Zuordnung darf mitten in der Animation wiederholt werden. Keine Eingabesperre.

### C. Ergebnis

1. **Aufbau:** Personenkarten erscheinen mit 40–60 ms Versatz (max. 4–6 sichtbar animiert, Rest sofort), Beträge zählen 600 ms hoch, danach ruhig.
2. **Summe stimmt:** ein Haken-Moment (Haken zeichnet sich 300 ms), Haptik „Erfolg“, kein Konfetti als Standard (Apple: Bewegung mit Absicht, nicht für Dauerhäufiges) [HIG geprüft].
3. **Summe stimmt nicht:** Differenz als Zeile direkt an der Summe, Haptik „Warnung“ einmal, Hinweis „Tippe auf die Zeile, die nicht passt“. Der Marker bleibt stehen, bewegt sich nicht. Zeilen mit geringer Erkennungssicherheit bekommen den stehenden Marker (Abschnitt B.2).
4. **Export:** Fortschritt nur, wenn es dauert (> 1 s); sonst direkt Bestätigung.

### D. Querschnitt

- **Ein Bewegungsprofil,** drei Federn: *Antippen* 380/0,55→0,8; *Bewegen* 700/0,9; *Einblenden* Effekte 1600/1,0. Alle über eine zentrale Stelle, die `disableAnimations`/`reduceMotion`/App-Schalter prüft.
- **Nie nur Bewegung:** jede Bewegung hat Text oder stehende Form als Zwilling (Projektregel „jede Geste hat einen sichtbaren Zwilling“, `/home/claude/fasan-camera/CLAUDE.md`).
- **Haptik-Paare, fest:** Start = Aufprall leicht; Auswahl = Auswahl-Tick; Summe stimmt = Erfolg; Abweichung = Warnung; Fehler = Fehler. Je Muster nur eine Bedeutung. Haptik abschaltbar.
- **Messen statt glauben:** Echtzeiten der sechs Stufen auf drei Geräten messen. Erst danach Stufengewichte und die „dauert länger“-Schwelle festlegen. Wirkung der Scan-Linie gegen „nur Stufentext“ im Nutzertest vergleichen (keine Studie dazu gefunden).

## Offene Punkte für die nächste Runde

1. WWDC18 803 Transkript gelesen 04.11. (siehe „Nachgelesen WWDC18 803“ unten); die Zahlenwerte aus der Sekundärquelle bleiben ungeprüft.
2. Offizielle M3-/Compose-Quelle für Federwerte lesen, nicht den Port.
3. NN/g „Skeleton Screens“ und Aufmerksamkeit/Banner-Blindheit (Benway & Lane, NN/g) lesen.
4. Harrison et al. 2010 Paper (Zahlen zu Pulsen/Wellen im Balken).
5. Buell & Norton 2011 Volltext (Wartezeiten, Grenzen der Labor Illusion).
6. Android-Haptik-Doku (developer.android.com) und Flutter `HapticFeedback` lesen, bevor Muster zugeordnet werden.
7. Flutter `SpringDescription` und `AnimationController` mit Reduce-Motion in api.flutter.dev lesen.

## Nachgelesen WWDC18 803 (04.11.)

Quelle: Transkript auf https://developer.apple.com/videos/play/wwdc2018/803/ („Designing Fluid Interfaces“), per curl gelesen.
**[geprüft]** im Transkript:
- Antwort: Menschen sind sehr empfindlich gegen Verzögerung; schon etwas Lag macht es „losgelöst“. Bilder pro Sekunde allein genügen nicht („60 fps und fühlt sich trotzdem falsch an“).
- Dämpfung = Überschwingen: 100 % ohne Überschwingen, 0 % schwingt endlos. Antwort = wie schnell die Feder reagiert. Masse, Steifigkeit, Dämpfung bleiben im Hintergrund; Entwürfe nutzen nur diese zwei Regler.
- Unterbrechen und Umlenken jederzeit zulassen (Beispiel: App starten und gleich zurückwerfen).
- Projektion: aus Geschwindigkeit und Abbremsrate die „gedachte“ Endposition berechnen und dorthin umlenken, statt zum nächsten Rand zu springen.
- 30 fps strobt bei schneller Bewegung; 60 fps erlaubt schnellere Bewegung ohne Strobing; Bewegungsunschärfe hilft.
**[nicht geprüft]**: Die Zahlenwerte (Verschieben Dämpfung 1,0 / Antwort 0,4 s usw.) stehen im Transkript **nicht** (keine Dezimalzahl dort). Sie bleiben [Sekundär]; Videobild/Folien nicht gesehen. Flutter-`SpringDescription.withDampingRatio` und Android-Entsprechungen weiter [nicht geprüft].
