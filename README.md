# fasan_ui

Gemeinsames Designpaket der Fasan-Apps (Flutter, MPL-2.0): Tokens, Stile, Filmeffekte, Bewegung, Bausteine,
Haptik und Akku-Stufen. Genutzt von Fasan Split, später Fasan Karte, Kamera und Player.

Beschlüsse: `fasan-app/Fasan` → `ENTSCHEIDUNGEN.md` (01.11.2026). Recherche: `docs/recherche/2026-11-01-design-grundlagen.md`.

## Inhalt

| Teil | Datei | Was |
| --- | --- | --- |
| Tokens | `lib/src/tokens.dart` | Abstände, Radien, Tippflächen (48/60 dp), Dauern 150/220/320 ms |
| Einstellungen | `lib/src/settings.dart` | Stil, Akzent, Schrift, Hell/Dunkel, Filmeffekte, Akku-Modus, Bewegung, Haptik, „Einfach“ |
| Akku | `lib/src/power.dart`, `android/…/FasanUiPlugin.kt` | Akkustand, Energiesparmodus, Wärmestatus; Stufen Voll / Sparen / Akku maximal |
| Themes | `lib/src/theme.dart` | sechs Stile × hell/dunkel × drei Akzente; `FasanLook` als ThemeExtension |
| Bewegung, Haptik | `lib/src/scope.dart` | folgt „Animationen entfernen“ und „Weniger Bewegung“; Federn; HapticFeedback |
| Filmeffekte | `lib/src/effects/film.dart`, `shaders/` | Korn, Bildstandwackeln, Glow, Halation, Lichtüberstrahlung |
| Bausteine | `lib/src/widgets/widgets.dart` | Glas, Knopf, Segmente, Avatare, Personen-Chips, Fortschritt mit Rillen, Eckklammern, Analyse-Linie |
| Galerie | `lib/src/gallery.dart` | Seite „Aussehen“ mit Vorschau und Vergleich aller Stile |

## Nutzung

```dart
final c = FasanController(settings: FasanSettings.decode(gespeichert), onChanged: (s) => speichern(s.encode()));
await c.start(); // Akku-Zustand (Android)
runApp(FasanScope(controller: c, child: ListenableBuilder(listenable: c, builder: (_, __) => MaterialApp(
  theme: c.theme(Brightness.light), darkTheme: c.theme(Brightness.dark), themeMode: c.themeMode,
  home: const FasanFilm(child: Start()),
))));
```

## Tests

`flutter test`: Kontrast aller Stile und Akzente (Text ≥ 7:1, Nebentext und Akzent ≥ 4,5:1), Akku-Stufen,
Speichern/Laden, Bewegung aus, Tippflächen, Galerie rendert.

## Lizenzen

Code MPL-2.0. Schriften Inter und Geist: SIL Open Font License 1.1 (`fonts/OFL-*.txt`).
