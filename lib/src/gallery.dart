// fasan_ui – gallery for comparing styles, accents, fonts and effects; also the appearance settings page. MPL-2.0
import 'package:flutter/material.dart';

import 'effects/film.dart';
import 'power.dart';
import 'scope.dart';
import 'settings.dart';
import 'theme.dart';
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
  String get bleed => de ? 'Lichtüberstrahlung' : 'Light bleeding';
  String get weave => de ? 'Bildstandwackeln' : 'Gate weave';
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
          ClipRRect(borderRadius: BorderRadius.circular(l.radius), child: const SizedBox(height: 260, child: FasanFilm(child: FasanSample()))),
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
          // only effects that work (Regel: nur zeigen, was wirklich funktioniert); see FasanFilm.bloomVerified
          if (FasanFilm.bloomVerified) ...[
            slider(t.glow, s.effects.glow, (x) => s.effects.copyWith(glow: x)),
            slider(t.halation, s.effects.halation, (x) => s.effects.copyWith(halation: x)),
            slider(t.bleed, s.effects.bleed, (x) => s.effects.copyWith(bleed: x)),
          ],
          slider(t.weave, s.effects.weave, (x) => s.effects.copyWith(weave: x)),
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
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(l.radius), child: const FasanFilm(child: FasanSample()))),
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
    Widget content = Container(
      color: l.background,
      padding: const EdgeInsets.fromLTRB(FasanSpace.l, FasanSpace.l, FasanSpace.l, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FasanLabel(l.style.cinematic ? 'REF 0427 · LIS' : 'Lissabon'),
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
