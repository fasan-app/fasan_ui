// fasan_ui – building blocks: glass, pressable, button, segments, person avatars, progress, overlays. MPL-2.0
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../scope.dart';
import '../settings.dart';
import '../theme.dart';
import '../tokens.dart';

/// Glass panel for the control layer (bars, sheets). Never for content (Apple HIG Liquid Glass: separate layer).
/// Without blur (Braun, saving power) it becomes an opaque surface with a hairline.
class FasanGlass extends StatelessWidget {
  const FasanGlass({super.key, required this.child, this.padding, this.radius, this.highlight = 0});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  /// 0–1: short light response on touch ("Glas leuchtet beim Tippen").
  final double highlight;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final r = BorderRadius.circular(radius ?? l.radius);
    final dark = l.brightness == Brightness.dark;
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: l.glassTint,
        borderRadius: r,
        border: Border.all(color: l.hairline, width: 0.8),
        gradient: l.glassBlur > 0
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: (dark ? 0.07 : 0.35) + 0.25 * highlight),
                  Colors.white.withValues(alpha: dark ? 0.0 : 0.05),
                ],
              )
            : null,
      ),
      child: Padding(padding: padding ?? const EdgeInsets.all(FasanSpace.m), child: child),
    );
    if (l.glassBlur <= 0) return panel;
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: l.glassBlur, sigmaY: l.glassBlur), child: panel),
    );
  }
}

/// Scales down slightly while pressed and springs back (velocity-free spring, FasanMotion.spring).
/// Gives haptic feedback on tap. The hit area is at least FasanLook.minTap.
class FasanPressable extends StatefulWidget {
  const FasanPressable({super.key, required this.child, this.onTap, this.onLongPress, this.semanticLabel, this.scale = 0.96});

  final Widget child;
  final VoidCallback? onTap, onLongPress;
  final String? semanticLabel;
  final double scale;

  @override
  State<FasanPressable> createState() => _FasanPressableState();
}

class _FasanPressableState extends State<FasanPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);

  void _to(double target) {
    final m = FasanMotion.of(context);
    if (!m.enabled) {
      _c.value = target;
      return;
    }
    _c.animateWith(SpringSimulation(m.spring, _c.value, target, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _to(widget.scale) : null,
        onTapCancel: enabled ? () => _to(1) : null,
        onTapUp: enabled ? (_) => _to(1) : null,
        onTap: widget.onTap == null
            ? null
            : () {
                FasanHaptics.of(context).tap();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: l.minTap, minHeight: l.minTap),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) => Transform.scale(scale: _c.value, child: child),
            child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
          ),
        ),
      ),
    );
  }
}

enum FasanButtonKind { primary, secondary, quiet }

class FasanButton extends StatelessWidget {
  const FasanButton({super.key, required this.label, this.onPressed, this.icon, this.kind = FasanButtonKind.primary, this.expand = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FasanButtonKind kind;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final t = Theme.of(context).textTheme.labelLarge!;
    final disabled = onPressed == null;
    final (Color bg, Color fg, Color? border) = switch (kind) {
      FasanButtonKind.primary => (l.accent, l.onAccent, null),
      FasanButtonKind.secondary => (l.surfaceAlt, l.text, null),
      FasanButtonKind.quiet => (Colors.transparent, l.accent, l.hairline),
    };
    final cine = l.style.cinematic;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: FasanSpace.s)],
        Flexible(child: Text(cine ? label.toUpperCase() : label, style: t.copyWith(color: fg), overflow: TextOverflow.ellipsis)),
      ],
    );
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: FasanPressable(
        onTap: onPressed,
        semanticLabel: label,
        child: Container(
          constraints: BoxConstraints(minHeight: l.minTap, minWidth: expand ? double.infinity : 0),
          padding: const EdgeInsets.symmetric(horizontal: FasanSpace.xl, vertical: FasanSpace.m),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(l.style == FasanStyle.braun || cine ? l.radius : 999),
            border: border == null ? null : Border.all(color: border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Segmented control with a sliding indicator (Bewegung erklärt Veränderung).
class FasanSegmented<T> extends StatelessWidget {
  const FasanSegmented({super.key, required this.values, required this.selected, required this.label, required this.onChanged});

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final idx = math.max(0, values.indexOf(selected));
    final t = Theme.of(context).textTheme.labelMedium!;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth / values.length;
      return Container(
        height: l.minTap,
        decoration: BoxDecoration(color: l.surfaceAlt, borderRadius: BorderRadius.circular(l.radius * 0.7)),
        child: Stack(children: [
          AnimatedPositioned(
            duration: m.medium,
            curve: FasanCurves.medium,
            left: idx * w + 3,
            top: 3,
            bottom: 3,
            width: w - 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: l.surface,
                borderRadius: BorderRadius.circular(l.radius * 0.6),
                border: Border.all(color: l.hairline),
              ),
            ),
          ),
          Row(children: [
            for (final v in values)
              Expanded(
                child: Semantics(
                  selected: v == selected,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(l.radius * 0.6),
                    onTap: () {
                      FasanHaptics.of(context).tap();
                      onChanged(v);
                    },
                    child: Center(
                      child: Text(label(v),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.copyWith(color: v == selected ? l.text : l.textMuted, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
    });
  }
}

/// Person colours: distinct hues, readable initials (white on these in light, dark text in dark mode).
abstract final class FasanPeople {
  static const _light = [
    Color(0xFF2B54D6), Color(0xFFC2410C), Color(0xFF26745C), Color(0xFF8B3FB8),
    Color(0xFFB4235A), Color(0xFF5B6B12), Color(0xFF00708A), Color(0xFF7A5512),
  ];
  static const _dark = [
    Color(0xFF8AA4FF), Color(0xFFFF8A4C), Color(0xFF5CCFA5), Color(0xFFCB9BF0),
    Color(0xFFFF8FB4), Color(0xFFC3D46A), Color(0xFF6FD3EA), Color(0xFFE6B866),
  ];

  static Color color(int i, Brightness b) => (b == Brightness.dark ? _dark : _light)[i % _light.length];
  static Color on(Brightness b) => b == Brightness.dark ? const Color(0xFF0B0B0C) : Colors.white;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }
}

class FasanAvatar extends StatelessWidget {
  const FasanAvatar({super.key, required this.name, required this.index, this.size = 32, this.ring = false});

  final String name;
  final int index;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final c = FasanPeople.color(index, l.brightness);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: ring ? l.text : l.surface, width: ring ? 2 : 1.5),
      ),
      child: Text(
        FasanPeople.initials(name),
        style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w700, color: FasanPeople.on(l.brightness), height: 1),
      ),
    );
  }
}

/// Overlapping avatars for shared items (Plan: Avatare statt Farbstreifen).
class FasanAvatarStack extends StatelessWidget {
  const FasanAvatarStack({super.key, required this.people, this.size = 26, this.max = 4});

  /// (name, colour index) pairs.
  final List<(String, int)> people;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(max).toList();
    final more = people.length - shown.length;
    final step = size * 0.62;
    final n = shown.length + (more > 0 ? 1 : 0);
    return SizedBox(
      width: n == 0 ? 0 : size + step * (n - 1),
      height: size,
      child: Stack(children: [
        for (var i = 0; i < shown.length; i++)
          Positioned(left: i * step, child: FasanAvatar(name: shown[i].$1, index: shown[i].$2, size: size)),
        if (more > 0)
          Positioned(
            left: shown.length * step,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: FasanLook.of(context).surfaceAlt, shape: BoxShape.circle),
              child: Text('+$more', style: TextStyle(fontSize: size * 0.36, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

/// Selectable person chip: avatar + name; selected = filled with the person's colour.
class FasanPersonChip extends StatelessWidget {
  const FasanPersonChip({super.key, required this.name, required this.index, required this.selected, this.onTap});

  final String name;
  final int index;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final c = FasanPeople.color(index, l.brightness);
    return Semantics(
      selected: selected,
      child: FasanPressable(
        onTap: onTap,
        semanticLabel: name,
        child: AnimatedContainer(
          duration: m.short,
          curve: FasanCurves.short,
          constraints: BoxConstraints(minHeight: l.minTap),
          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
          decoration: BoxDecoration(
            color: selected ? c : l.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? c : l.hairline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            FasanAvatar(name: name, index: index, size: 34),
            const SizedBox(width: 8),
            Text(name,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: selected ? FasanPeople.on(l.brightness) : l.text)),
            if (selected) ...[const SizedBox(width: 6), Icon(Icons.check_rounded, size: 18, color: FasanPeople.on(l.brightness))],
          ]),
        ),
      ),
    );
  }
}

/// Progress bar with grooves running backwards: feels faster (Harrison, Yeo & Hudson 2010, GRUNDSAETZE.md).
/// Without motion the grooves stand still.
class FasanProgress extends StatefulWidget {
  const FasanProgress({super.key, required this.value, this.height = 6});

  /// 0–1, or null for indeterminate.
  final double? value;
  final double height;

  @override
  State<FasanProgress> createState() => _FasanProgressState();
}

class _FasanProgressState extends State<FasanProgress> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    final run = m.enabled && l.level == FasanPowerLevel.full;
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
    return Semantics(
      value: widget.value == null ? null : '${(widget.value! * 100).round()} %',
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _GroovePainter(widget.value, run ? _c.value : 0, l.accent, l.surfaceAlt),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _GroovePainter extends CustomPainter {
  _GroovePainter(this.value, this.phase, this.color, this.track);

  final double? value;
  final double phase;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.height / 2));
    canvas.drawRRect(r, Paint()..color = track);
    final v = value ?? 1;
    final fill = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width * v.clamp(0, 1), size.height), Radius.circular(size.height / 2));
    canvas.save();
    canvas.clipRRect(fill);
    canvas.drawRRect(fill, Paint()..color = color);
    // Grooves: diagonal light stripes moving right-to-left (against the direction of progress).
    final p = Paint()..color = Colors.white.withValues(alpha: 0.22);
    final gap = size.height * 3;
    for (double x = -gap * 2 - phase * gap; x < size.width + gap; x += gap) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height * 2, 0)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GroovePainter o) => o.value != value || o.phase != phase || o.color != color;
}

/// Corner brackets around a region (machine overlay). Thin, precise lines; no decoration beyond that.
class FasanBrackets extends StatelessWidget {
  const FasanBrackets({super.key, required this.child, this.label, this.color, this.inset = 0});

  final Widget child;
  final String? label;
  final Color? color;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final c = color ?? l.line;
    return CustomPaint(
      foregroundPainter: _BracketPainter(c, inset),
      child: Stack(clipBehavior: Clip.none, children: [
        child,
        if (label != null)
          Positioned(
            left: inset + 2,
            top: -16,
            child: Text(label!, style: l.mono(10, color: c, weight: FontWeight.w500)),
          ),
      ]),
    );
  }
}

class _BracketPainter extends CustomPainter {
  _BracketPainter(this.color, this.inset);

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final k = math.min(16.0, math.min(s.width, s.height) * 0.25);
    final r = Rect.fromLTRB(inset, inset, s.width - inset, s.height - inset);
    for (final (o, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(o, o + Offset(k * dx, 0), p);
      canvas.drawLine(o, o + Offset(0, k * dy), p);
    }
  }

  @override
  bool shouldRepaint(_BracketPainter o) => o.color != color || o.inset != inset;
}

/// Analysis sweep: a thin line moving down over a region while work is running (machine / sci-fi styles).
/// Stands still without motion or while saving power.
class FasanSweep extends StatefulWidget {
  const FasanSweep({super.key, required this.active});

  final bool active;

  @override
  State<FasanSweep> createState() => _FasanSweepState();
}

class _FasanSweepState extends State<FasanSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final run = widget.active && FasanMotion.of(context).enabled && l.level == FasanPowerLevel.full;
    if (run && !_c.isAnimating) {
      _c.repeat();
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _SweepPainter(run ? _c.value : 0.5, l.line), size: Size.infinite),
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  _SweepPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height * Curves.easeInOut.transform(t);
    final rect = Rect.fromLTWH(0, y - 24, s.width, 24);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.22)],
        ).createShader(rect),
    );
    canvas.drawLine(Offset(0, y), Offset(s.width, y), Paint()..color = color..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(_SweepPainter o) => o.t != t || o.color != color;
}

/// Small caps label for sections; monospace in cinematic styles.
class FasanLabel extends StatelessWidget {
  const FasanLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    if (l.style.cinematic) return Text(text.toUpperCase(), style: l.mono(11, weight: FontWeight.w500));
    return Text(text, style: Theme.of(context).textTheme.labelMedium);
  }
}
