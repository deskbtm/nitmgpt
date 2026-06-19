import 'package:flutter/cupertino.dart';
import 'package:nitmgpt/theme/app_theme.dart';

import 'bottom_bar_models.dart';
import 'bottom_bar_tab_item.dart';
import 'frosted_bar_surface.dart';
import 'frosted_jelly_indicator.dart';
import 'spring_builder.dart';
import 'tab_drag_gesture_mixin.dart';

/// Tab pill — one icon per slot (color only), jelly droplet slides underneath.
class FrostedTabIndicator extends StatefulWidget {
  const FrostedTabIndicator({
    super.key,
    required this.tabs,
    required this.tabIndex,
    required this.onTabChanged,
    required this.visible,
    required this.barHeight,
    required this.barBorderRadius,
    required this.tabPadding,
    required this.isSearchActive,
    required this.onDismissSearch,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.iconSize,
    required this.labelFontSize,
    required this.iconLabelSpacing,
    this.textStyle,
    this.indicatorColor,
    this.indicatorExpansion = 14,
    this.pressScale = 1.04,
    this.collapsedLogoBuilder,
  });

  final List<BottomBarTab> tabs;
  final int tabIndex;
  final bool visible;
  final ValueChanged<int> onTabChanged;
  final double barHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;
  final bool isSearchActive;
  final VoidCallback onDismissSearch;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final double iconSize;
  final double labelFontSize;
  final double iconLabelSpacing;
  final TextStyle? textStyle;
  final Color? indicatorColor;
  final double indicatorExpansion;
  final double pressScale;
  final WidgetBuilder? collapsedLogoBuilder;

  int get tabCount => tabs.length;

  @override
  State<FrostedTabIndicator> createState() => FrostedTabIndicatorState();
}

class FrostedTabIndicatorState extends State<FrostedTabIndicator>
    with TabDragGestureMixin<FrostedTabIndicator> {
  @override
  int get tabCount => widget.tabCount;

  @override
  int get tabIndex => widget.tabIndex;

  @override
  void notifyTabChanged(int index) => widget.onTabChanged(index);

  @override
  void didUpdateWidget(covariant FrostedTabIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateTabAlignIfNeeded(oldWidget.tabIndex, oldWidget.tabCount);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSearchActive) {
      return SizedBox(
        height: widget.barHeight,
        child: FrostedBarSurface(
          borderRadius: widget.barBorderRadius,
          circular: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismissSearch,
            child: widget.collapsedLogoBuilder != null
                ? widget.collapsedLogoBuilder!(context)
                : const SizedBox.expand(),
          ),
        ),
      );
    }

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final indicatorColor = widget.indicatorColor ??
        bottomBarIndicatorFrostColor(isDark: isDark);
    final targetAlign = computeTabAlignment(widget.tabIndex);
    final backgroundRadius = widget.barBorderRadius * 2;
    final glassRadius = widget.barBorderRadius;

    return SpringBuilder(
      spring: GlassSpring.smooth(duration: const Duration(milliseconds: 250)),
      value: barSwayOffset,
      builder: (context, sway, _) {
        return Transform.translate(
          offset: Offset(sway, 0),
          child: Listener(
            onPointerDown: (_) {
              if (mounted) setState(() => tabIsDown = true);
            },
            onPointerUp: (_) {
              if (!tabIsDragging && mounted) setState(() => tabIsDown = false);
            },
            onPointerCancel: (_) {
              if (!tabIsDragging && mounted) setState(() => tabIsDown = false);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragDown: onBarDragDown,
              onHorizontalDragStart: onBarDragStart,
              onHorizontalDragUpdate: onBarDragUpdate,
              onHorizontalDragEnd: onBarDragEnd,
              onHorizontalDragCancel: onBarDragCancel,
              onTapDown: onBarTapDown,
              child: VelocitySpringBuilder(
                value: tabXAlign,
                springWhenActive: GlassSpring.interactive(),
                springWhenReleased: GlassSpring.snappy(
                  duration: const Duration(milliseconds: 350),
                ),
                active: tabIsDragging,
                builder: (context, alignX, velocity, _) {
                  final alignment = Alignment(alignX, 0);
                  return SpringBuilder(
                    spring: GlassSpring.snappy(
                      duration: const Duration(milliseconds: 300),
                    ),
                    value: widget.visible &&
                            (tabIsDown ||
                                (alignX - targetAlign).abs() > 0.05)
                        ? 1.0
                        : 0.0,
                    builder: (context, thickness, _) {
                      final radius =
                          thickness < 1 ? backgroundRadius : glassRadius;
                      final overflow =
                          bottomBarJellyOverflow(widget.indicatorExpansion);

                      return SpringBuilder(
                        spring: GlassSpring.smooth(
                          duration: const Duration(milliseconds: 200),
                        ),
                        value: tabIsDown ? widget.pressScale : 1.0,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          height: widget.barHeight,
                          width: double.infinity,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: widget.barHeight,
                                child: FrostedBarSurface(
                                  borderRadius: widget.barBorderRadius,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                top: -overflow,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      height: widget.barHeight,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          if (widget.visible)
                                            FrostedJellyIndicator(
                                              itemCount: widget.tabCount,
                                              alignment: alignment,
                                              thickness: thickness,
                                              velocity: velocity,
                                              indicatorColor: indicatorColor,
                                              borderRadius: radius,
                                              expansion:
                                                  widget.indicatorExpansion,
                                            ),
                                          Positioned.fill(
                                            child: Padding(
                                              padding: widget.tabPadding,
                                              child: Row(
                                                children: [
                                                  for (var i = 0;
                                                      i < widget.tabs.length;
                                                      i++)
                                                    Expanded(
                                                      child: BottomBarTabItem(
                                                        tab: widget.tabs[i],
                                                        selected: widget
                                                                .tabIndex ==
                                                            i,
                                                        selectedIconColor: widget
                                                            .selectedIconColor,
                                                        unselectedIconColor:
                                                            widget
                                                                .unselectedIconColor,
                                                        iconSize:
                                                            widget.iconSize,
                                                        labelFontSize: widget
                                                            .labelFontSize,
                                                        textStyle:
                                                            widget.textStyle,
                                                        iconLabelSpacing: widget
                                                            .iconLabelSpacing,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
