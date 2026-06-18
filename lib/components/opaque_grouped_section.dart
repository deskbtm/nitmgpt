import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nitmgpt/components/frosted_glass_surface.dart';
import 'package:nitmgpt/theme.dart';
import 'package:unicons/unicons.dart';

/// iOS-style grouped list with opaque frosted surface tiles.
class OpaqueGroupedSection extends StatelessWidget {
  const OpaqueGroupedSection({
    super.key,
    this.header,
    this.headerStyle,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final String? header;
  final TextStyle? headerStyle;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final visibleChildren = children.where(_isVisibleChild).toList();
    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFF8E8E93).withValues(alpha: 0.58);

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                header!,
                style: headerStyle ??
                    TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          FrostedGlassSurface(
            blurred: true,
            fillColor: tileFrostFillColor(isDark: isDark),
            borderColor: tileFrostBorderColor(isDark: isDark),
            child: Column(
              children: [
                for (var i = 0; i < visibleChildren.length; i++) ...[
                  visibleChildren[i],
                  if (i < visibleChildren.length - 1)
                    _GroupedDashedDivider(color: dividerColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool _isVisibleChild(Widget child) {
    if (child is SizedBox) {
      final width = child.width ?? 0;
      final height = child.height ?? 0;
      return !(width == 0 && height == 0 && child.child == null);
    }
    return true;
  }
}

class _GroupedDashedDivider extends StatelessWidget {
  const _GroupedDashedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DottedLine(
          dashColor: color,
          dashGapColor: Colors.transparent,
          lineThickness: 1,
          dashLength: 4,
          dashGapLength: 3,
          dashRadius: 0.5,
        ),
      ),
    );
  }
}

/// Standard settings-style row with optional chevron.
class OpaqueListTile extends StatelessWidget {
  const OpaqueListTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.horizontalTitleGap,
    this.minLeadingWidth,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final double? horizontalTitleGap;
  final double? minLeadingWidth;

  @override
  Widget build(BuildContext context) {
    Widget? effectiveTrailing = trailing;
    if (showChevron && trailing == null) {
      effectiveTrailing = Icon(
        UniconsLine.angle_right,
        size: 18,
        color: CupertinoColors.tertiaryLabel.resolveFrom(context),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: effectiveTrailing,
          horizontalTitleGap: horizontalTitleGap ?? 16,
          minLeadingWidth: minLeadingWidth ?? 40,
        ),
      ),
    );
  }
}
