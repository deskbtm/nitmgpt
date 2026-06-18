import 'package:flutter/material.dart';
import 'package:nitmgpt/core/frosted_glass.dart';
import 'package:nitmgpt/theme.dart';

/// Frosted pill surface for the bottom navigation bar.
class FrostedBarSurface extends StatelessWidget {
  const FrostedBarSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.circular = false,
    this.clipChild = true,
  });

  final Widget child;
  final double borderRadius;
  final bool circular;
  final bool clipChild;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = circular
        ? BorderRadius.circular(borderRadius * 100)
        : BorderRadius.circular(borderRadius);

    final border = Border.all(color: bottomBarFrostBorderColor(isDark: isDark));
    final fillColor = bottomBarFrostFillColor(isDark: isDark);
    final shadows = bottomBarFrostShadows(isDark: isDark);

    final frostedBackdrop = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: kBottomBarFrostBlurFilter,
        child: ColoredBox(
          color: fillColor,
          child: clipChild ? child : const SizedBox.expand(),
        ),
      ),
    );

    if (clipChild) {
      return RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
            boxShadow: shadows,
          ),
          child: frostedBackdrop,
        ),
      );
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: shadows),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(child: frostedBackdrop),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: border,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
