import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/core/frosted_glass.dart';
import 'package:unicons/unicons.dart';

/// Secondary-page back control — frosted glass (BackdropFilter), not liquid glass.
class AppBarBackButton extends StatelessWidget {
  const AppBarBackButton({super.key});

  static const _size = 44.0;
  static const _iconSize = 20.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final frostColor = isDark
        ? surfaceColor.withValues(alpha: 0.72)
        : surfaceColor.withValues(alpha: 0.68);
    final borderColor = Colors.white.withValues(alpha: isDark ? 0.12 : 0.5);
    final iconColor = Theme.of(context).colorScheme.onSurface;

    return RepaintBoundary(
      child: SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: kFrostedGlassBlurFilter,
              child: Material(
                color: frostColor,
                child: InkWell(
                  onTap: () => context.pop(),
                  child: Center(
                    child: Icon(
                      UniconsLine.angle_left_b,
                      size: _iconSize,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
