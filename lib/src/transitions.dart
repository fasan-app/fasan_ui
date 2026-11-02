// fasan_ui – filmic transitions (GESTALTUNG.md §7). MPL-2.0
//
// Uses package:animations 3.0.0 (Flutter team, BSD-3-Clause): SharedAxisTransition, FadeThroughTransition, OpenContainer.
// Pages are transparent over FasanBackdrop, so fillColor is transparent: the ground stays still while pages move.
// Reduced motion (system „Animationen entfernen“ or app „Weniger Bewegung“): a short cross-fade (≤ 150 ms), no travel.
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'scope.dart';
import 'theme.dart';

/// Page transitions for all routes: shared axis X; fade when motion is reduced.
class FasanPageTransitionsBuilder extends PageTransitionsBuilder {
  const FasanPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (!FasanMotion.of(context).enabled) {
      return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)), child: child);
    }
    return SharedAxisTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      transitionType: SharedAxisTransitionType.horizontal,
      fillColor: Colors.transparent,
      child: child,
    );
  }
}

/// Switches between views of the same thing (e.g. scan / original / digital receipt) with fade through.
class FasanFadeThrough extends StatelessWidget {
  const FasanFadeThrough({super.key, required this.child});

  /// Give the child a key that changes with the view.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final m = FasanMotion.of(context);
    return PageTransitionSwitcher(
      duration: m.enabled ? const Duration(milliseconds: 260) : const Duration(milliseconds: 120),
      transitionBuilder: (child, a, b) => m.enabled
          ? FadeThroughTransition(animation: a, secondaryAnimation: b, fillColor: Colors.transparent, child: child)
          : FadeTransition(opacity: a, child: child),
      child: child,
    );
  }
}

/// A card that opens into a page by growing out of itself (container transform).
class FasanOpenContainer extends StatelessWidget {
  const FasanOpenContainer({super.key, required this.closedBuilder, required this.openBuilder, this.radius, this.onClosed});

  /// Call `open` to start the transition.
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder openBuilder;
  final double? radius;
  final VoidCallback? onClosed;

  @override
  Widget build(BuildContext context) {
    final l = FasanLook.of(context);
    final m = FasanMotion.of(context);
    return OpenContainer<Object?>(
      closedColor: l.surface,
      openColor: l.background,
      middleColor: l.surface,
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius ?? l.radius)),
      tappable: false,
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: m.enabled ? const Duration(milliseconds: 420) : const Duration(milliseconds: 150),
      onClosed: onClosed == null ? null : (_) => onClosed!(),
      // During the transition the closed card is drawn in the overlay, outside the page's Material: give ink a surface.
      closedBuilder: (context, open) => Material(type: MaterialType.transparency, child: closedBuilder(context, open)),
      openBuilder: (context, _) => openBuilder(context),
    );
  }
}
