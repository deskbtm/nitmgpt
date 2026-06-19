import 'package:flutter/material.dart';
import 'package:nitmgpt/core/frosted_glass.dart';
import 'package:nitmgpt/theme/app_theme.dart';

/// Frosted surface — [BackdropFilter] blur plus semi-opaque fill and soft border.
class FrostedGlassSurface extends StatelessWidget {
  const FrostedGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = kTileBorderRadiusAll,
    this.margin,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
    this.fillColor,
    this.borderColor,
    this.blurred = false,
  });

  final Widget child;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Clip clipBehavior;
  final Color? fillColor;
  final Color? borderColor;
  final bool blurred;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedFill = fillColor ?? _defaultFillColor(context);
    final resolvedBorder = borderColor ?? _defaultBorderColor(context);
    final resolvedRadius = borderRadius.resolve(Directionality.of(context));

    final inner = padding == null ? child : Padding(padding: padding!, child: child);

    Widget filledContent = Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: ColoredBox(color: resolvedFill),
        ),
        inner,
      ],
    );

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: resolvedBorder, width: 1),
        boxShadow: blurred ? tileFrostShadows(isDark: isDark) : null,
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius,
        clipBehavior: clipBehavior,
        child: blurred
            ? BackdropFilter(
                filter: kTileFrostBlurFilter,
                child: filledContent,
              )
            : filledContent,
      ),
    );

    if (blurred) {
      surface = RepaintBoundary(child: surface);
    }

    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }

    return surface;
  }
}
