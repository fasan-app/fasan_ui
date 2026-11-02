# Navigation, Layoutänderungen, Papierkorb, verschlüsselte Relays, Korn, Glas, Ton (Kurzfassung, 02.11.2026)

Auftrag des Nutzers 02.11. abends. Quellen per Suche gelesen; jede Annahme ohne Quelle ist als „nicht geprüft“ markiert.

## 1. Navigation: drei Reiter unten plus schwebendes Plus
- Material 3: Eine Navigationsleiste enthält drei bis fünf Ziele (Jetpack-Compose-Doku und Material-Leitfäden). Für Aktionen gibt es
  den Floating Action Button; die Bottom App Bar vereint Ziele, Aktionen und FAB. Tabs sind das sekundäre Muster für Ansichten innerhalb eines
  Ziels (developer.android.com, Layout- und Navigationsmuster).
- Apple iOS 26: Die Tab-Leiste ist Liquid Glass und schwebt über dem Inhalt, die Tab-Leiste kann beim Scrollen schrumpfen
  (WWDC25 Session 284, Apple HIG). Die Primäraktion über der Leiste ist üblich, aber nicht Teil der Standardleiste (Drittbibliothek FabBar).
- Entscheidung: unten drei Reiter (Rechnungen, Gruppen, Freunde), rechts ein schwebendes Plus. Auf „Rechnungen“ stehen oben die drei Ansichten
  Offen, Archiv, Papierkorb. Das Plus fragt im zweiten Schritt: Kamera, Galerie/Datei, ohne Bon. Auf Gruppen und Freunde legt es eine Gruppe
  bzw. einen Freund an. Einladungen liegen in der Gruppe, Einstellungen oben rechts.
- Wischen: Ein einziger horizontaler Pager trägt alle fünf Seiten (Offen, Archiv, Papierkorb, Gruppen, Freunde). Ältere Material-Studien
  empfehlen, zwischen Reitern der unteren Leiste nicht zu wischen; das gilt hier bewusst nicht, weil der Nutzer es verlangt. Konflikt mit dem
  Wischen auf einer Kachel: Die Kachel (Dismissible) gewinnt, auf freier Fläche und Kopfzeilen wischt der Pager (Gestenarena, nicht auf dem Gerät geprüft).

## 2. Layoutänderungen: nie springen
- Apple: Zustandsänderungen animieren (SwiftUI `withAnimation`, `animation(_:value:)`, Transitions für Ein- und Ausblenden; HIG „Motion“: knappe,
  präzise Animation; Animation nie als einziges Signal, dazu Haptik und Ton). Flutter-Entsprechung: `AnimatedSize` zusammen mit `AnimatedSwitcher`.
- Umsetzung: `FasanReveal` (Größe animiert, Inhalt blendet, gleiche Kurve wie der Stil). Ohne Bewegung kein `AnimatedSize` (mit Dauer 0 beendet
  es sich im eigenen Layout und löst eine Assertion aus; im Test gefunden). Auswahl nur durch Farbe, kein Häkchen (ein Häkchen macht die Chips
  breiter und die Liste darunter springt).

## 3. Papierkorb und Archiv
- Üblich sind 30 Tage: Apple „Zuletzt gelöscht“ 30 Tage, Google Drive und Gmail 30 Tage, Google Photos 30 Tage (früher 60), Google Keep 7 Tage
  (TechRepublic, PhoneArena). Archiv und Papierkorb sind verschieden (Gmail).
- Entscheidung: „Fertig“ = Archiv; Löschen = Papierkorb; Frist 7 Tage, 30 Tage (Standard) oder nur manuell (Einstellungen → Daten).

## 4. Verschlüsselt über öffentliche Nostr-Relays
- Technisch ja: NIP-44 (versionierte Verschlüsselung), NIP-59 (Gift Wrap: Siegel kind 13, Umschlag kind 1059 mit Einmalschlüssel, Zeit zufällig bis 2 Tage
  zurück), NIP-17 (private Nachrichten; „Messages can flow through public relays without loss of privacy“; kein öffentlicher Gruppenbezeichner).
  Löschen ist nur eine Bitte (NIP-09, NIP-62): einmal veröffentlichte Ereignisse lassen sich nicht sicher zurückholen.
- Folge für die Arbeit: Jeder Test gegen öffentliche Relays schreibt dauerhaft. Nach Beschluss 02.11. nur mit ausdrücklicher Freigabe für genau
  diesen Test. Gebaut wird gegen einen lokalen Relay in der Sitzung; öffentliche Relays erst nach Freigabe.

## 5. Filmkorn nach AV1 (Kurzfassung)
- AV1-Filmkornsynthese (Norkin und Birkbeck, DCC 2018; Spezifikation 7.18.3; libaom BSD-2, dav1d BSD-2): Aus einer gaußschen Zufallsfolge entsteht
  mit einem autoregressiven Filter (Lag bis 3, 24 Koeffizienten) eine Vorlage von 82×73 Werten. Das Bild wird in 32×32-Blöcke geteilt, jeder Block
  nimmt einen zufälligen Ausschnitt der Vorlage (Versatz aus einem Zufallsgenerator je Bild und Zeile), Blöcke überlappen 2 Pixel. Die Stärke
  folgt einer stückweise linearen Funktion der Helligkeit (bis 14 Stützpunkte). Das Korn ist also räumlich korreliert (kein weißes Rauschen wie
  „ISO-Rauschen“) und hat Blockstruktur mit zufälligem Versatz.
- Umsetzung in fasan_ui: Vorlage in Dart erzeugt (Seed, AR-Filter), als kleine Textur an den Shader; Blöcke, Versatz und Helligkeitsfunktion im Shader.

## 6. Glas
- fluid_glass (Port von Kyant0/AndroidLiquidGlass; Lizenz auf pub.dev „unknown“, deshalb nur als Vorbild gelesen, nichts kopiert): Hintergrund wird
  einmal je Frame mit `OffsetLayer.toImageSync` erfasst, Brechung und Lichtkante laufen in Fragment-Shadern; ohne `ImageFilter.shader`
  (Impeller) fällt es auf einfaches Weichzeichnen zurück. Apple iOS 26: Glas gehört in die Funktionsschicht (Leisten, Schaltflächen, Sheets), nicht auf Inhaltskarten
  (WWDC25 Session 323/284, HIG).

## 7. Ton
- Flutter `SystemSound` kennt auf Android nur `click` (`alert` nur Desktop); der Klick folgt den „Touch-Tönen“ des Systems (Drittquelle, nicht auf
  One UI geprüft). Eigene Töne über audioplayers: `AudioContextAndroid.usageType` kann `assistanceSonification` sein (Oberflächentöne); `respectSilence`
  verlangt `USAGE_NOTIFICATION_RINGTONE` und folgt dem Lautlos-Schalter (Quellcode audioplayers_platform_interface).
