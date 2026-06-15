import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:unicons/unicons.dart';

/// Opaque iOS-style grouped list — for scrollable content areas.
///
/// Per [liquid_glass_widgets design philosophy](https://github.com/sdegenaar/liquid_glass_widgets#glass-vs-content--design-philosophy),
/// glass is for navigation chrome; list rows stay opaque.
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
    if (children.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final dividerColor = isDark
        ? CupertinoColors.separator.darkColor
        : CupertinoColors.separator.color;

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
          Material(
            color: surface.withValues(alpha: isDark ? 0.94 : 0.92),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: 1, indent: 16, endIndent: 16, color: dividerColor),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard settings-style row with optional chevron.
class OpaqueListTile extends StatelessWidget {
  const OpaqueListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = false,
    this.onTap,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;

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

    return ListTile(
      title: title,
      subtitle: subtitle,
      trailing: effectiveTrailing,
      onTap: onTap,
    );
  }
}
