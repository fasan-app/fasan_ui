// fasan_ui – gallery for comparing styles, accents, fonts and effects; also the appearance settings page. MPL-2.0
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';

import 'effects/backdrop.dart';
import 'effects/film.dart';
import 'effects/glass_shader.dart';
import 'power.dart';
import 'scope.dart';
import 'settings.dart';
import 'theme.dart';
import 'tilt.dart';
import 'tokens.dart';
import 'widgets/widgets.dart';

/// German and English strings of fasan_ui (Du-Form, kurze Sätze).
class FasanStrings {
  const FasanStrings._(this.de);

  final bool de;

  static FasanStrings of(BuildContext context) => FasanStrings._(Localizations.maybeLocaleOf(context)?.languageCode != 'en');

  String style(FasanStyle s) => switch (s) {
        FasanStyle.calmGlass => de ? 'Ruhe + Glas' : 'Calm + glass',
        FasanStyle.braun => de ? 'Braun' : 'Braun',
        FasanStyle.fullGlass => de ? 'Volles Glas' : 'Full glass',
        FasanStyle.machine => de ? 'Maschine' : 'Machine',
        FasanStyle.sciFi => 'Sci-Fi',
        FasanStyle.spy => de ? 'Spionage' : 'Spy',
      };
  String accent(FasanAccent a) => switch (a) {
        FasanAccent.signal => de ? 'Signal' : 'Signal',
        FasanAccent.cobalt => de ? 'Kobalt' : 'Cobalt',
        FasanAccent.sage => de ? 'Salbei' : 'Sage',
      };
  String font(FasanFont f) => switch (f) {
        FasanFont.inter => 'Inter',
        FasanFont.system => de ? 'System' : 'System',
        FasanFont.geist => 'Geist',
      };
  String battery(FasanBatteryMode m) => switch (m) {
        FasanBatteryMode.auto => de ? 'Automatisch' : 'Automatic',
        FasanBatteryMode.maximum => de ? 'Akku maximal' : 'Max battery',
        FasanBatteryMode.never => de ? 'Nie sparen' : 'Never save',
      };
  String theme(FasanThemeMode m) => switch (m) {
        FasanThemeMode.system => de ? 'System' : 'System',
        FasanThemeMode.light => de ? 'Hell' : 'Light',
        FasanThemeMode.dark => de ? 'Dunkel' : 'Dark',
      };
  String get title => de ? 'Aussehen' : 'Appearance';
  String get styleLabel => de ? 'Stil' : 'Style';
  String get accentLabel => de ? 'Akzent' : 'Accent';
  String get fontLabel => de ? 'Schrift' : 'Font';
  String get themeLabel => de ? 'Hell oder dunkel' : 'Light or dark';
  String get effects => de ? 'Filmeffekte' : 'Film effects';
  String get effectsOn => de ? 'Filmeffekte an' : 'Film effects on';
  String get grain => de ? 'Korn' : 'Grain';
  String get glow => 'Glow';
  String get halation => 'Halation';
  String get bleed => de ? 'Überstrahlen' : 'Light bleeding';
  String get weave => de ? 'Bildstandwackeln' : 'Gate weave';
  String get grainSize => de ? 'Korngröße' : 'Grain size';
  String get grainSoft => de ? 'Korn weich' : 'Grain softness';
  String get grainClump => de ? 'Korn klumpig' : 'Grain clumping';
  String get grainChroma => de ? 'Farbrauschen' : 'Colour noise';
  String get oldFilm => de ? 'Alter Film' : 'Old film';
  String oldFilmName(FasanOldFilm v) => switch (v) {
        FasanOldFilm.auto => de ? 'Nur Kino-Stile' : 'Cinematic styles',
        FasanOldFilm.on => de ? 'Immer' : 'Always',
        FasanOldFilm.off => de ? 'Aus' : 'Off',
      };
  String get flicker => de ? 'Flackern' : 'Flicker';
  String get dust => de ? 'Staub' : 'Dust';
  String get scratches => de ? 'Kratzer' : 'Scratches';
  String get vignette => de ? 'Vignette' : 'Vignette';
  String get warmth => de ? 'Warmer Stich' : 'Warm cast';
  String get grainSpeed => de ? 'Korn-Tempo' : 'Grain speed';
  String get layer => de ? 'Korn und Wackeln' : 'Grain and weave';
  String layerName(FasanFilmLayer v) => switch (v) {
        FasanFilmLayer.ground => de ? 'Nur Hintergrund' : 'Background only',
        FasanFilmLayer.whole => de ? 'Ganzes Bild' : 'Whole picture',
      };
  String get gradient => de ? 'Farbverlauf im Hintergrund' : 'Background gradient';
  String get lightSweep => de ? 'Lichteinfall' : 'Light sweep';
  String get tilt => de ? 'Glas folgt der Neigung' : 'Glass follows tilt';
  String get transparency => de ? 'Transparenz reduzieren' : 'Reduce transparency';
  String get transparencyHint => de ? 'Glas wird zur festen Fläche.' : 'Glass becomes a solid surface.';
  String get lab => de ? 'Effekte prüfen' : 'Test effects';
  String get labSolo => de ? 'Nur einen Effekt zeigen' : 'Show one effect';
  String get labAll => de ? 'Alle' : 'All';
  String get labTilt => de ? 'Neigung' : 'Tilt';
  String get labNoSensor => de ? 'Kein Lagesensor – Regler simuliert die Neigung.' : 'No motion sensor – the slider simulates tilt.';
  String get labFps => de ? 'Bilder pro Sekunde' : 'Frames per second';
  String get labPulse => de ? 'Ring-Impuls zeigen' : 'Play ring pulse';
  String get batteryLabel => de ? 'Akku' : 'Battery';
  String get batteryHint => de
      ? 'Bei wenig Akku, im Energiesparmodus oder wenn das Handy warm ist, laufen keine Effekte.'
      : 'With low battery, power saving or a warm phone, effects pause.';
  String get batteryMaxHint => de
      ? '„Akku maximal“: dunkel, keine Effekte, kürzeste Animationen. Den Energiesparmodus des Handys schaltest du selbst.'
      : '"Max battery": dark, no effects, shortest animations. Turn on the phone\'s battery saver yourself.';
  String get openSaver => de ? 'Energiesparmodus öffnen' : 'Open battery saver';
  String get motion => de ? 'Weniger Bewegung' : 'Reduce motion';
  String get motionHint => de ? 'Die Systemoption „Animationen entfernen“ gilt immer.' : 'The system option "Remove animations" always applies.';
  String get haptics => de ? 'Haptik' : 'Haptics';
  String get simple => de ? 'Große Bedienung' : 'Large controls';
  String get preview => de ? 'Vorschau' : 'Preview';
  String get compare => de ? 'Alle Stile' : 'All styles';
  String get sample => de ? 'Abendessen Alfama' : 'Dinner in Alfama';
  String get sampleSub => de ? '4 Personen · 86,40 €' : '4 people · €86.40';
  String get action => de ? 'Bon scannen' : 'Scan receipt';
  String get second => de ? 'Später' : 'Later';
  String state(FasanPowerLevel l) => switch (l) {
        FasanPowerLevel.full => de ? 'Effekte laufen' : 'Effects running',
        FasanPowerLevel.save => de ? 'Akku wird geschont' : 'Saving battery',
        FasanPowerLevel.maximum => de ? 'Akku maximal' : 'Max battery',
      };
}

/// Appearance settings with a live preview. Apps link it from their settings ("Aussehen").
class FasanAppearancePage extends StatelessWidget {
  const FasanAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FasanScope.of(context);
    final s = c.settings;
    final t = FasanStrings.of(context);
    final l = FasanLook.of(context);
    Widget slider(String name, double v, FilmEffectSettings Function(double) set) => Row(children: [
          SizedBox(width: 132, child: Text(name, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(
            child: Slider(
              value: v,
              onChanged: s.effects.enabled ? (x) => c.update((o) => o.copyWith(effects: set(x))) : null,
            ),
          ),
        ]);
    return Scaffold(
      appBar: AppBar(title: Text(t.title), actions: [
        TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FasanGalleryPage())),
          child: Text(t.compare),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FasanSpace.l, 0, FasanSpace.l, FasanSpace.xxxl),
        children: [
          FasanLabel(t.preview),
          const SizedBox(height: FasanSpace.s),
          ClipRRect(borderRadius: BorderRadius.circular(l.radius), child: const SizedBox(height: 260, child: FasanBackdrop(child: FasanFilm(child: FasanSample())))),
          const SizedBox(height: FasanSpace.s),
          Text(t.state(c.level), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: FasanSpace.xl),
          FasanLabel(t.styleLabel),
          const SizedBox(height: FasanSpace.s),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final v in FasanStyle.values)
              ChoiceChip(label: Text(t.style(v)), selected: s.style == v, onSelected: (_) => c.update((o) => o.copyWith(style: v))),
          ]),
          const SizedBox(height: FasanSpace.l),
          FasanLabel(t.accentLabel),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanAccent>(values: FasanAccent.values, selected: s.accent, label: t.accent, onChanged: (v) => c.update((o) => o.copyWith(accent: v))),
          const SizedBox(height: FasanSpace.l),
          FasanLabel(t.fontLabel),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanFont>(values: FasanFont.values, selected: s.font, label: t.font, onChanged: (v) => c.update((o) => o.copyWith(font: v))),
          const SizedBox(height: FasanSpace.l),
          FasanLabel(t.themeLabel),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanThemeMode>(values: FasanThemeMode.values, selected: s.themeMode, label: t.theme, onChanged: (v) => c.update((o) => o.copyWith(themeMode: v))),
          const SizedBox(height: FasanSpace.xl),
          FasanLabel(t.effects),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.effectsOn),
            value: s.effects.enabled,
            onChanged: (v) => c.update((o) => o.copyWith(effects: o.effects.copyWith(enabled: v))),
          ),
          slider(t.grain, s.effects.grain, (x) => s.effects.copyWith(grain: x)),
          slider(t.grainSize, s.effects.grainSize, (x) => s.effects.copyWith(grainSize: x)),
          slider(t.grainSpeed, s.effects.grainSpeed, (x) => s.effects.copyWith(grainSpeed: x)),
          slider(t.grainSoft, s.effects.grainSoft, (x) => s.effects.copyWith(grainSoft: x)),
          slider(t.grainClump, s.effects.grainClump, (x) => s.effects.copyWith(grainClump: x)),
          slider(t.grainChroma, s.effects.grainChroma, (x) => s.effects.copyWith(grainChroma: x)),
          const SizedBox(height: FasanSpace.s),
          Text(t.oldFilm, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanOldFilm>(
            values: FasanOldFilm.values,
            selected: s.effects.oldFilm,
            label: t.oldFilmName,
            onChanged: (v) => c.update((o) => o.copyWith(effects: o.effects.copyWith(oldFilm: v))),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.vignette),
            value: s.effects.vignetteOn || s.effects.oldFilmFor(s.style),
            onChanged: s.effects.oldFilmFor(s.style) ? null : (v) => c.update((o) => o.copyWith(effects: o.effects.copyWith(vignetteOn: v))),
          ),
          if (s.effects.vignetteOn && !s.effects.oldFilmFor(s.style)) slider(t.vignette, s.effects.vignette, (x) => s.effects.copyWith(vignette: x)),
          if (s.effects.oldFilmFor(s.style)) ...[
            slider(t.flicker, s.effects.flicker, (x) => s.effects.copyWith(flicker: x)),
            slider(t.dust, s.effects.dust, (x) => s.effects.copyWith(dust: x)),
            slider(t.scratches, s.effects.scratches, (x) => s.effects.copyWith(scratches: x)),
            slider(t.vignette, s.effects.vignette, (x) => s.effects.copyWith(vignette: x)),
            slider(t.warmth, s.effects.warmth, (x) => s.effects.copyWith(warmth: x)),
          ],
          slider(t.weave, s.effects.weave, (x) => s.effects.copyWith(weave: x)),
          slider(t.glow, s.effects.glow, (x) => s.effects.copyWith(glow: x)),
          slider(t.halation, s.effects.halation, (x) => s.effects.copyWith(halation: x)),
          slider(t.bleed, s.effects.bleed, (x) => s.effects.copyWith(bleed: x)),
          const SizedBox(height: FasanSpace.s),
          Text(t.layer, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanFilmLayer>(
            values: FasanFilmLayer.values,
            selected: s.effects.layer,
            label: t.layerName,
            onChanged: (v) => c.update((o) => o.copyWith(effects: o.effects.copyWith(layer: v))),
          ),
          for (final (name, value, set) in [
            (t.gradient, s.effects.gradient, (bool v) => s.effects.copyWith(gradient: v)),
            (t.lightSweep, s.effects.lightSweep, (bool v) => s.effects.copyWith(lightSweep: v)),
            (t.tilt, s.effects.tilt, (bool v) => s.effects.copyWith(tilt: v)),
          ])
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              value: value,
              onChanged: s.effects.enabled ? (v) => c.update((o) => o.copyWith(effects: set(v))) : null,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.transparency),
            subtitle: Text(t.transparencyHint),
            value: s.reduceTransparency,
            onChanged: (v) => c.update((o) => o.copyWith(reduceTransparency: v)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.science_outlined),
              label: Text(t.lab),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FasanEffectLab())),
            ),
          ),
          const SizedBox(height: FasanSpace.l),
          FasanLabel(t.batteryLabel),
          const SizedBox(height: FasanSpace.s),
          FasanSegmented<FasanBatteryMode>(values: FasanBatteryMode.values, selected: s.battery, label: t.battery, onChanged: (v) => c.update((o) => o.copyWith(battery: v))),
          const SizedBox(height: FasanSpace.s),
          Text(s.battery == FasanBatteryMode.maximum ? t.batteryMaxHint : t.batteryHint, style: Theme.of(context).textTheme.bodySmall),
          if (s.battery == FasanBatteryMode.maximum)
            Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: FasanPower.openBatterySaverSettings, child: Text(t.openSaver))),
          const SizedBox(height: FasanSpace.l),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t.motion),
            subtitle: Text(t.motionHint),
            value: s.reduceMotion,
            onChanged: (v) => c.update((o) => o.copyWith(reduceMotion: v)),
          ),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.haptics), value: s.haptics, onChanged: (v) => c.update((o) => o.copyWith(haptics: v))),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t.simple), value: s.simpleProfile, onChanged: (v) => c.update((o) => o.copyWith(simpleProfile: v))),
        ],
      ),
    );
  }
}

/// All six styles next to each other, each in its own theme, light and dark.
class FasanGalleryPage extends StatelessWidget {
  const FasanGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = FasanScope.of(context);
    final t = FasanStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.compare)),
      body: LayoutBuilder(builder: (context, box) {
        final cols = box.maxWidth > 900 ? 3 : (box.maxWidth > 560 ? 2 : 1);
        return GridView.count(
          crossAxisCount: cols,
          padding: const EdgeInsets.all(FasanSpace.l),
          mainAxisSpacing: FasanSpace.l,
          crossAxisSpacing: FasanSpace.l,
          childAspectRatio: 1.25,
          children: [
            for (final st in FasanStyle.values)
              for (final b in [Brightness.light, Brightness.dark])
                _Tile(settings: c.settings.copyWith(style: st), brightness: b, level: c.level, title: '${t.style(st)} · ${b == Brightness.dark ? t.theme(FasanThemeMode.dark) : t.theme(FasanThemeMode.light)}', onTap: () {
                  c.update((o) => o.copyWith(style: st));
                  Navigator.of(context).maybePop();
                }),
          ],
        );
      }),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.settings, required this.brightness, required this.level, required this.title, required this.onTap});

  final FasanSettings settings;
  final Brightness brightness;
  final FasanPowerLevel level;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FasanThemes.theme(settings, brightness, level);
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Theme(
          data: theme,
          child: Builder(builder: (context) {
            final l = FasanLook.of(context);
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: FasanLook.of(context).textMuted)),
              const SizedBox(height: 6),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(l.radius), child: const FasanBackdrop(child: FasanFilm(child: FasanSample())))),
            ]);
          }),
        ),
      ),
    );
  }
}

/// A small, representative screen (title, people, list rows, glass bar, button) to judge a style.
class FasanSample extends StatelessWidget {
  const FasanSample({super.key});

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final t = FasanStrings.of(context);
    final tt = Theme.of(context).textTheme;
    final people = [('Christopher', 0), ('Anna', 1), ('Jo', 2), ('Mia', 3)];
    final rows = [('Bacalhau à Brás', '18,50', [0, 1]), ('Vinho Verde', '24,00', [0, 1, 2, 3]), ('Pastel de Nata ×4', '6,40', [2])];
    Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(FasanSpace.l, FasanSpace.l, FasanSpace.l, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FasanLabel('Lissabon'),
        const SizedBox(height: 4),
        Text(t.sample, style: tt.titleLarge),
        Text(t.sampleSub, style: tt.bodySmall),
        const SizedBox(height: FasanSpace.m),
        FasanAvatarStack(people: people, size: 28),
        const SizedBox(height: FasanSpace.m),
        Expanded(
          child: ClipRect(
            child: ListView(physics: const NeverScrollableScrollPhysics(), padding: EdgeInsets.zero, children: [
              for (final r in rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(color: l.surface, borderRadius: BorderRadius.circular(l.radius * 0.6), border: Border.all(color: l.hairline)),
                  child: Row(children: [
                    Expanded(child: Text(r.$1, style: tt.bodyMedium, overflow: TextOverflow.ellipsis)),
                    FasanAvatarStack(people: [for (final i in r.$3) people[i]], size: 20),
                    const SizedBox(width: 10),
                    Text(r.$2, style: tt.bodyMedium!.copyWith(fontFeatures: const [FontFeature.tabularFigures()], fontWeight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ),
        ),
      ]),
    );
    if (l.style.cinematic) {
      content = Stack(children: [
        content,
        Positioned(left: 8, right: 8, top: 8, bottom: 8, child: IgnorePointer(child: FasanBrackets(child: const SizedBox.expand()))),
      ]);
    }
    return Stack(children: [
      Positioned.fill(child: content),
      Positioned(
        left: FasanSpace.m,
        right: FasanSpace.m,
        bottom: FasanSpace.m,
        child: FasanGlass(
          padding: const EdgeInsets.all(6),
          child: Row(children: [
            Expanded(child: FasanButton(label: t.action, icon: Icons.document_scanner_outlined, onPressed: () {}, expand: true)),
          ]),
        ),
      ),
    ]);
  }
}

/// Effect test page (GESTALTUNG.md §8): every effect alone, live tilt values, sensor rate and frame rate.
/// For checking on a real phone (S23 first) before a style is accepted.
class FasanEffectLab extends StatefulWidget {
  const FasanEffectLab({super.key});

  @override
  State<FasanEffectLab> createState() => _FasanEffectLabState();
}

enum _Solo { all, gradient, grain, weave, sweep, bleed, glow, glass }

class _FasanEffectLabState extends State<FasanEffectLab> {
  _Solo _solo = _Solo.all;
  int _pulse = 0;
  double _fps = 0;
  Timer? _poll;
  void _timings(List<ui.FrameTiming> list) {
    if (list.isEmpty) return;
    // totalSpan = build + raster time per frame; the inverse is the frame rate the device could sustain.
    final total = list.map((f) => f.totalSpan.inMicroseconds).reduce((a, b) => a + b) / list.length;
    if (mounted && total > 0) setState(() => _fps = 1e6 / total);
  }

  @override
  void initState() {
    super.initState();
    FasanTilt.instance.acquire();
    SchedulerBinding.instance.addTimingsCallback(_timings);
    _poll = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    FasanTilt.instance.release();
    super.dispose();
  }

  FilmEffectSettings _effects(FilmEffectSettings base) {
    if (_solo == _Solo.all) return base;
    const none = FilmEffectSettings(grain: 0, glow: 0, halation: 0, bleed: 0, weave: 0, gradient: false, lightSweep: false, tilt: false);
    return switch (_solo) {
      _Solo.gradient => none.copyWith(gradient: true),
      _Solo.grain => none.copyWith(grain: base.grain > 0 ? base.grain : 0.35, grainSize: base.grainSize, grainSpeed: base.grainSpeed),
      _Solo.weave => none.copyWith(weave: base.weave > 0 ? base.weave : 0.4, gradient: true),
      _Solo.sweep => none.copyWith(lightSweep: true),
      _Solo.bleed => none.copyWith(bleed: base.bleed > 0 ? base.bleed : 0.25, tilt: true),
      _Solo.glow => none.copyWith(glow: base.glow > 0 ? base.glow : 0.5, halation: base.halation > 0 ? base.halation : 0.35),
      _Solo.glass => none.copyWith(tilt: true, gradient: true),
      _Solo.all => base,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = FasanStrings.of(context);
    final l = FasanLook.of(context);
    final tt = Theme.of(context).textTheme;
    final tilt = FasanTilt.instance;
    final fx = _effects(l.effects);
    final names = {
      _Solo.all: t.labAll, _Solo.gradient: t.gradient, _Solo.grain: t.grain, _Solo.weave: t.weave,
      _Solo.sweep: t.lightSweep, _Solo.bleed: t.bleed, _Solo.glow: '${t.glow} + ${t.halation}', _Solo.glass: t.tilt,
    };
    final noSensor = tilt.source == 'none' || tilt.source == '';
    return Scaffold(
      appBar: AppBar(title: Text(t.lab)),
      body: ListView(padding: const EdgeInsets.fromLTRB(FasanSpace.l, 0, FasanSpace.l, FasanSpace.xxxl), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(l.radius),
          child: SizedBox(
            height: 340,
            child: Theme(
              data: Theme.of(context).copyWith(extensions: [l.copyWith(effects: fx)]),
              child: FasanBackdrop(
                effects: fx,
                child: Padding(
                  padding: const EdgeInsets.all(FasanSpace.l),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('86,40 €', style: tt.displaySmall),
                    Text(t.sampleSub, style: tt.bodySmall),
                    const Spacer(),
                    FasanGlass(child: Row(children: [
                      const Icon(Icons.receipt_long_outlined),
                      const SizedBox(width: FasanSpace.m),
                      Expanded(child: Text(t.sample, style: tt.titleMedium)),
                    ])),
                    const SizedBox(height: FasanSpace.l),
                    FasanGlow(pulse: _pulse, radius: 999, child: FasanButton(label: t.action, onPressed: () {}, expand: true, glow: false)),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: FasanSpace.l),
        FasanLabel(t.labSolo),
        const SizedBox(height: FasanSpace.s),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final v in _Solo.values) ChoiceChip(label: Text(names[v]!), selected: _solo == v, onSelected: (_) => setState(() => _solo = v)),
        ]),
        const SizedBox(height: FasanSpace.l),
        Align(alignment: Alignment.centerLeft, child: TextButton(onPressed: () => setState(() => _pulse++), child: Text(t.labPulse))),
        const SizedBox(height: FasanSpace.l),
        FasanLabel(t.labTilt),
        Text(
          'x ${tilt.value.dx.toStringAsFixed(2)} · y ${tilt.value.dy.toStringAsFixed(2)} · ${tilt.source.isEmpty ? '–' : tilt.source} · ${tilt.rate.toStringAsFixed(0)} Hz',
          style: l.mono(13, color: l.text),
        ),
        if (noSensor) ...[
          Text(t.labNoSensor, style: tt.bodySmall),
          Slider(value: tilt.value.dx, min: -1, max: 1, onChanged: (v) => setState(() => tilt.simulate(Offset(v, tilt.value.dy)))),
        ],
        const SizedBox(height: FasanSpace.s),
        Text('${t.labFps}: ${_fps.toStringAsFixed(0)} · ${t.grainSize}: ${fx.grainPx.toStringAsFixed(1)} px', style: l.mono(13, color: l.text)),
        // glass stage chosen by the start-up probe (glass_shader.dart)
        Text('Glas: ${FasanGlassShader.tier.value.name}${FasanGlassShader.reason == null ? '' : ' · ${FasanGlassShader.reason}'}', style: l.mono(13, color: l.text)),
      ]),
    );
  }
}
