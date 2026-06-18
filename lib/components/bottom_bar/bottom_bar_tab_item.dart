import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'bottom_bar_models.dart';

class BottomBarTabItem extends StatelessWidget {
  const BottomBarTabItem({
    super.key,
    required this.tab,
    required this.selected,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.labelFontSize,
    required this.iconLabelSpacing,
    this.textStyle,
    this.onTap,
  });

  final BottomBarTab tab;
  final bool selected;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double iconSize;
  final double labelFontSize;
  final double iconLabelSpacing;
  final TextStyle? textStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? selectedIconColor : unselectedIconColor;
    final iconWidget = selected ? (tab.activeIcon ?? tab.icon) : tab.icon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: selected,
        label: tab.label ?? 'Tab',
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: iconLabelSpacing,
              children: [
                IconTheme(
                  data: IconThemeData(color: iconColor, size: iconSize),
                  child: iconWidget,
                ),
                if (tab.label != null)
                  Text(
                    tab.label!,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle ??
                        TextStyle(
                          color: iconColor,
                          fontSize: labelFontSize,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
