import 'dart:math' as math;

import 'package:fasan_ui/fasan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x relative luminance and contrast ratio (w3.org/TR/WCAG21/#dfn-contrast-ratio).
double _lum(Color c) {
  double ch(double v) => v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  group('Kontrast', () {
    for (final st in FasanStyle.values) {
      for (final b in Brightness.values) {
        for (final a in FasanAccent.values) {
          test('${st.name} ${b.name} ${a.name}', () {
            final l = FasanThemes.look(FasanSettings(style: st, accent: a), b, FasanPowerLevel.full);
            expect(contrast(l.text, l.background), greaterThanOrEqualTo(7.0), reason: 'Text auf Hintergrund');
            expect(contrast(l.text, l.surface), greaterThanOrEqualTo(7.0), reason: 'Text auf Fläche');
            expect(contrast(l.textMuted, l.surface), greaterThanOrEqualTo(4.5), reason: 'Nebentext');
            expect(contrast(l.onAccent, l.accent), greaterThanOrEqualTo(4.5), reason: 'Schrift auf Akzent');
          });
        }
      }
    }
    test('Personenfarben tragen ihre Initialen lesbar', () {
      for (final b in Brightness.values) {
        for (var i = 0; i < 8; i++) {
          expect(contrast(FasanPeople.on(b), FasanPeople.color(i, b)), greaterThanOrEqualTo(4.5), reason: '$b $i');
        }
      }
    });
  });

  group('Akku-Stufen', () {
    const s = FasanSettings();
    test('voll im Normalfall', () => expect(s.powerLevel(const FasanPowerState(battery: 80)), FasanPowerLevel.full));
    test('sparen bei 20 % ohne Laden', () => expect(s.powerLevel(const FasanPowerState(battery: 20)), FasanPowerLevel.save));
    test('kein Sparen beim Laden', () => expect(s.powerLevel(const FasanPowerState(battery: 15, charging: true)), FasanPowerLevel.full));
    test('Energiesparmodus', () => expect(s.powerLevel(const FasanPowerState(battery: 90, powerSave: true)), FasanPowerLevel.save));
    test('Wärme ab MODERATE', () => expect(s.powerLevel(const FasanPowerState(battery: 90, thermal: 2)), FasanPowerLevel.save));
    test('Akku maximal immer', () => expect(s.copyWith(battery: FasanBatteryMode.maximum).powerLevel(const FasanPowerState(battery: 100)), FasanPowerLevel.maximum));
    test('Nie sparen bleibt voll', () => expect(s.copyWith(battery: FasanBatteryMode.never).powerLevel(const FasanPowerState(battery: 5, powerSave: true)), FasanPowerLevel.full));
    test('Sparen: kein Weichzeichner, keine Effekte', () {
      final l = FasanThemes.look(const FasanSettings(), Brightness.light, FasanPowerLevel.save);
      expect(l.glassBlur, 0);
      expect(l.effectsActive, isFalse);
    });
  });

  test('Gewählte Schrift gilt für alle Textstile (Fehler in 0.1)', () {
    for (final (font, family) in [(FasanFont.inter, 'packages/fasan_ui/FasanInter'), (FasanFont.geist, 'packages/fasan_ui/FasanGeist'), (FasanFont.system, null)]) {
      for (final style in FasanStyle.values) {
        final t = FasanThemes.theme(FasanSettings(font: font, style: style), Brightness.light, FasanPowerLevel.full).textTheme;
        for (final ts in [t.displaySmall, t.headlineSmall, t.titleLarge, t.titleMedium, t.bodyLarge, t.bodyMedium, t.bodySmall, t.labelLarge, t.labelMedium]) {
          expect(ts?.fontFamily, family, reason: '$font $style');
        }
      }
    }
  });

  test('Einstellungen speichern und laden', () {
    const s = FasanSettings(style: FasanStyle.spy, accent: FasanAccent.sage, font: FasanFont.geist, battery: FasanBatteryMode.maximum, effects: FilmEffectSettings(grain: 0.7));
    final d = FasanSettings.decode(s.encode());
    expect(d.style, FasanStyle.spy);
    expect(d.accent, FasanAccent.sage);
    expect(d.font, FasanFont.geist);
    expect(d.battery, FasanBatteryMode.maximum);
    expect(d.effects.grain, closeTo(0.7, 1e-9));
    expect(FasanSettings.decode('kaputt').style, FasanStyle.calmGlass);
  });

  testWidgets('Bewegung folgt „Animationen entfernen“ und „Weniger Bewegung“', (tester) async {
    final c = FasanController();
    late FasanMotion a, b;
    await tester.pumpWidget(FasanScope(
      controller: c,
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (context) {
          a = FasanMotion.of(context);
          return const SizedBox();
        }),
      ),
    ));
    expect(a.medium, Duration.zero);
    c.update((s) => s.copyWith(reduceMotion: true));
    await tester.pumpWidget(FasanScope(
      controller: c,
      child: Builder(builder: (context) {
        b = FasanMotion.of(context);
        return const SizedBox();
      }),
    ));
    expect(b.long, Duration.zero);
  });

  testWidgets('Galerie und Aussehen rendern alle Stile ohne Fehler', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final c = FasanController();
    for (final st in FasanStyle.values) {
      c.update((s) => s.copyWith(style: st));
      await tester.pumpWidget(FasanScope(
        controller: c,
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => MaterialApp(theme: c.theme(Brightness.light), darkTheme: c.theme(Brightness.dark), home: const FasanAppearancePage()),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.byType(TextButton).first); // Testumgebung ist englisch: „All styles“
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FasanSample), findsWidgets);
  });

  testWidgets('Tippflächen mindestens 48 dp, im Profil „Einfach“ 60 dp', (tester) async {
    for (final simple in [false, true]) {
      final c = FasanController(settings: FasanSettings(simpleProfile: simple));
      await tester.pumpWidget(FasanScope(
        controller: c,
        child: MaterialApp(
          theme: c.theme(Brightness.light),
          home: Scaffold(body: Center(child: FasanButton(label: 'OK', onPressed: () {}))),
        ),
      ));
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byType(FasanPressable));
      expect(size.height, greaterThanOrEqualTo(simple ? 60 : 48));
    }
  });

  test('Alte Effekt-Einstellungen (0.1) starten mit den neuen, merkbaren Standards; „aus“ bleibt aus', () {
    final old = FilmEffectSettings.fromJson({'enabled': false, 'grain': 0.1, 'weave': 0.15});
    expect(old.enabled, isFalse);
    expect(old.grain, const FilmEffectSettings().grain);
    final round = FilmEffectSettings.fromJson(const FilmEffectSettings(grain: 0.8, layer: FasanFilmLayer.whole, tilt: false).toJson());
    expect(round.grain, closeTo(0.8, 1e-9));
    expect(round.layer, FasanFilmLayer.whole);
    expect(round.tilt, isFalse);
    expect(const FilmEffectSettings(grainSize: 1).grainPx, 4);
    expect(const FilmEffectSettings().grainPx, closeTo(1, 0.01));
  });

  test('Wackeln bleibt unter 3 px', () {
    for (var t = 0.0; t < 60; t += 0.07) {
      final o = FasanFilm.weaveOffset(t, 1);
      expect(o.dx.abs(), lessThanOrEqualTo(3.0001));
      expect(o.dy.abs(), lessThanOrEqualTo(3.0001));
    }
  });

  testWidgets('Hintergrund, Glas, Glow und Effekt-Testseite rendern; Neigung ohne Sensor bleibt ruhig', (tester) async {
    final c = FasanController();
    await tester.pumpWidget(FasanScope(
      controller: c,
      child: MaterialApp(
        theme: c.theme(Brightness.dark),
        builder: (context, child) => FasanBackdrop(child: FasanFilm(child: child!)),
        home: const FasanEffectLab(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    FasanTilt.instance.simulate(const Offset(0.5, -0.3));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(ChoiceChip).at(2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byType(FasanGlass), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Ganzes Bild: Vorschau unter dem App-Korn legt kein zweites darüber', (tester) async {
    final c = FasanController(settings: const FasanSettings(effects: FilmEffectSettings(layer: FasanFilmLayer.whole)));
    late BuildContext inner;
    await tester.pumpWidget(FasanScope(
      controller: c,
      child: MaterialApp(
        theme: c.theme(Brightness.light),
        builder: (context, child) => FasanFilm(child: child!),
        home: Builder(builder: (context) {
          inner = context;
          return const SizedBox();
        }),
      ),
    ));
    await tester.pump();
    expect(FasanFilm.coversWhole(inner), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  test('Norm: alle Stile haben dieselben Textmaße (kein Springen beim Wechsel)', () {
    final ref = FasanThemes.theme(const FasanSettings(), Brightness.light, FasanPowerLevel.full).textTheme;
    for (final st in FasanStyle.values) {
      final t = FasanThemes.theme(FasanSettings(style: st), Brightness.light, FasanPowerLevel.full).textTheme;
      for (final (a, b) in [(t.bodyMedium!, ref.bodyMedium!), (t.labelLarge!, ref.labelLarge!), (t.labelMedium!, ref.labelMedium!), (t.titleMedium!, ref.titleMedium!), (t.titleLarge!, ref.titleLarge!)]) {
        expect([a.fontSize, a.height, a.letterSpacing], [b.fontSize, b.height, b.letterSpacing], reason: st.name);
      }
    }
  });

  test('Norm: Knopf-Radius und Glow werden beim Stilwechsel überblendet, nicht umgeschaltet', () {
    final a = FasanThemes.look(const FasanSettings(), Brightness.light, FasanPowerLevel.full);
    final b = FasanThemes.look(const FasanSettings(style: FasanStyle.braun), Brightness.light, FasanPowerLevel.full);
    final m = a.lerp(b, 0.5);
    expect(m.buttonRadius, closeTo((a.buttonRadius + b.buttonRadius) / 2, 1e-9));
    expect(m.glowScale, closeTo(0.5, 1e-9));
  });

  group('Rückmeldung', () {
    test('Einstellungen: Klick-Ton und direkte Vibration sind Standard an und überstehen Speichern/Laden', () {
      expect(const FasanSettings().sound, isTrue);
      expect(const FasanSettings().hapticsDirect, isTrue);
      final off = FasanSettings.decode(const FasanSettings(sound: false, hapticsDirect: false).encode());
      expect(off.sound, isFalse);
      expect(off.hapticsDirect, isFalse);
      // alte gespeicherte Einstellungen ohne die neuen Felder
      final old = FasanSettings.decode('{"haptics": true}');
      expect(old.sound, isTrue);
      expect(old.hapticsDirect, isTrue);
    });

    testWidgets('ohne Vibrator-Plugin fällt die direkte Vibration auf die System-Haptik zurück', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add('${call.method}:${call.arguments}');
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      late FasanHaptics h;
      await tester.pumpWidget(Builder(builder: (c) {
        h = FasanHaptics.of(c);
        return const SizedBox();
      }));
      await h.tap();
      expect(calls, contains('HapticFeedback.vibrate:HapticFeedbackType.selectionClick'));
      expect(calls.any((c) => c.startsWith('SystemSound.play')), isTrue, reason: 'Klick-Ton an');
    });
  });
}
