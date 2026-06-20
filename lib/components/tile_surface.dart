import 'package:flutter/material.dart';
import 'package:nitmgpt/theme/app_theme.dart';

/// Semi-opaque rounded surface for grouped settings and notification tiles.
class TileSurface extends StatelessWidget {
  const TileSurface({
    super.key,
    required this.child,
    this.borderRadius = kTileBorderRadiusAll,
    this.margin,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.fillColor,
    this.borderColor,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final Color? fillColor;
  final Color? borderColor;

  static const _borderWidth = 1.5;

  static Color _defaultFillColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return isDark
        ? surfaceColor.withValues(alpha: 0.90)
        : surfaceColor.withValues(alpha: 0.92);
  }

  static Color _defaultBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.white.withValues(alpha: isDark ? 0.12 : 0.5);
  }

  BorderRadius _innerRadius(BorderRadius outer) {
    return BorderRadius.lerp(
      outer,
      BorderRadius.zero,
      _borderWidth / kTileBorderRadius,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedFill = fillColor ?? _defaultFillColor(context);
    final resolvedBorder = borderColor ?? _defaultBorderColor(context);
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));
    final innerRadius = _innerRadius(resolvedRadius);

    final inner =
        padding == null ? child : Padding(padding: padding!, child: child);

    final filledContent = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ColoredBox(color: resolvedFill),
        ),
        inner,
      ],
    );

    // Inset fill so wallpaper shows in the ring; border is painted on top.
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: tileShadows(isDark: isDark),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Padding(
            padding: const EdgeInsets.all(_borderWidth),
            child: ClipRRect(
              borderRadius: innerRadius,
              clipBehavior: clipBehavior,
              child: filledContent,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: resolvedBorder,
                    width: _borderWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}
