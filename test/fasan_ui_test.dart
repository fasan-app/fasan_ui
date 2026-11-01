import 'dart:math' as math;

import 'package:fasan_ui/fasan_ui.dart';
import 'package:flutter/material.dart';
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
}
