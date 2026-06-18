import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'bottom_bar_models.dart';
import 'frosted_search_pill.dart';
import 'frosted_tab_indicator.dart';
import 'searchable_bottom_bar_controller.dart';

/// Frosted-glass bottom navigation bar with morphing search pill.
///
/// Mirrors [GlassSearchableBottomBar] layout and spring animations while using
/// lightweight [BackdropFilter] surfaces instead of liquid glass shaders.
class FrostedSearchableBottomBar extends StatefulWidget {
  const FrostedSearchableBottomBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.searchConfig,
    this.controller,
    this.isSearchActive = false,
    this.spacing = 8,
    this.horizontalPadding = 20,
    this.verticalPadding = 20,
    this.barHeight = 64,
    this.searchBarHeight = 50,
    this.barBorderRadius = 32,
    this.tabPadding = const EdgeInsets.symmetric(horizontal: 4),
    this.iconLabelSpacing = 4,
    this.showIndicator = true,
    this.indicatorColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.iconSize = 24,
    this.labelFontSize = 11,
    this.textStyle,
    this.tabWidth = 88,
    this.indicatorExpansion = 14,
    this.springDescription,
    this.tabPillAnchor = TabPillAnchor.start,
    this.onBarTap,
  })  : assert(tabs.length > 0, 'FrostedSearchableBottomBar requires tabs'),
        assert(
          selectedIndex >= 0 && selectedIndex < tabs.length,
          'selectedIndex out of range',
        );

  static const _kSpring =
      SpringDescription(mass: 1.0, stiffness: 350.0, damping: 30.0);

  final FrostedSearchableBottomBarController? controller;
  final SearchBarConfig searchConfig;
  final bool isSearchActive;
  final List<BottomBarTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final double spacing;
  final double horizontalPadding;
  final double verticalPadding;
  final double barHeight;
  final double searchBarHeight;
  final double barBorderRadius;
  final EdgeInsetsGeometry tabPadding;
  final double iconLabelSpacing;
  final bool showIndicator;
  final Color? indicatorColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final double iconSize;
  final double labelFontSize;
  final TextStyle? textStyle;
  final double? tabWidth;
  final double indicatorExpansion;
  final SpringDescription? springDescription;
  final TabPillAnchor tabPillAnchor;
  final VoidCallback? onBarTap;

  @override
  State<FrostedSearchableBottomBar> createState() =>
      _FrostedSearchableBottomBarState();
}

class _FrostedSearchableBottomBarState extends State<FrostedSearchableBottomBar>
    with TickerProviderStateMixin {
  late FrostedSearchableBottomBarController _controller;
  bool _ownsController = false;

  late AnimationController _tabWCtrl;
  late AnimationController _searchLeftCtrl;
  late AnimationController _searchWCtrl;

  void _onControllerChanged() => setState(() {});
  void _onSpringTick() => setState(() {});

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = FrostedSearchableBottomBarController();
      _ownsController = true;
    }
    _controller.addListener(_onControllerChanged);

    _tabWCtrl = _makeSpringController();
    _searchLeftCtrl = _makeSpringController();
    _searchWCtrl = _makeSpringController();
  }

  AnimationController _makeSpringController() {
    return AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
    )..addListener(_onSpringTick);
  }

  @override
  void didUpdateWidget(covariant FrostedSearchableBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) _controller.dispose();
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = FrostedSearchableBottomBarController();
        _ownsController = true;
      }
      _controller.addListener(_onControllerChanged);
    }
    _controller.onSearchActiveChanged(
      wasActive: oldWidget.isSearchActive,
      isActive: widget.isSearchActive,
    );
  }

  @override
  void dispose() {
    _tabWCtrl.dispose();
    _searchLeftCtrl.dispose();
    _searchWCtrl.dispose();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _onFocusLost() => _controller.onFocusChanged(false);

  @override
  Widget build(BuildContext context) {
    final dynamicLabelColor = CupertinoTheme.of(context)
            .textTheme
            .textStyle
            .color ??
        CupertinoColors.label;
    final resolvedSelectedIconColor =
        widget.selectedIconColor ?? dynamicLabelColor;
    final resolvedUnselectedIconColor =
        widget.unselectedIconColor ?? dynamicLabelColor;
    final searching = widget.isSearchActive;

    final barContent = TweenAnimationBuilder<double>(
      tween: Tween<double>(
        end: searching ? widget.searchBarHeight : widget.barHeight,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, animH, _) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.horizontalPadding,
            vertical: widget.verticalPadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalW = constraints.maxWidth;
              final keyboardH = MediaQuery.viewInsetsOf(context).bottom;
              final keyboardPresent = keyboardH > 0;
              final hasDismiss = widget.searchConfig.showsCancelButton;
              final isKeyboardActive =
                  _controller.searchFocused && keyboardPresent;
              final dismissVisible = searching &&
                  _controller.searchFocused &&
                  hasDismiss &&
                  keyboardPresent;

              final layout = _controller.computeLayout(
                totalW: totalW,
                searching: widget.isSearchActive,
                expandWhenActive: widget.searchConfig.expandWhenActive,
                barHeight: widget.barHeight,
                searchBarHeight: widget.searchBarHeight,
                spacing: widget.spacing,
                hasDismiss: hasDismiss,
                dismissVisible: dismissVisible,
                collapsedTabWidth: widget.searchConfig.collapsedTabWidth,
                tabPillAnchor: widget.tabPillAnchor,
                extraFullW: 0,
                extraPos: ExtraButtonPosition.beforeSearch,
                extraCollapsesOnSearch: true,
                isKeyboardActive: isKeyboardActive,
                keyboardH: keyboardH,
                tabCount: widget.tabs.length,
                perTabWidth: widget.tabWidth,
              );

              final targetTabW = layout.targetTabW;
              final targetSearchLeft = layout.targetSearchLeft;
              final targetSearchW = layout.targetSearchW;
              final targetH =
                  searching ? widget.searchBarHeight : widget.barHeight;
              final centeredTab =
                  widget.tabPillAnchor == TabPillAnchor.center;
              final maxTabW = totalW -
                  targetH -
                  widget.spacing;

              if (!_controller.pillsInitialized &&
                  !_controller.pillsInitScheduled) {
                _controller.markInitScheduled(totalW: totalW);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _tabWCtrl.value = targetTabW;
                  _searchLeftCtrl.value = targetSearchLeft;
                  _searchWCtrl.value = targetSearchW;
                  _controller.initializePills(
                    tabW: targetTabW,
                    searchLeft: targetSearchLeft,
                    searchW: targetSearchW,
                  );
                });
              } else if (_controller.pillsInitialized) {
                final retarget = _controller.checkRetarget(layout);
                if (retarget.any) {
                  final fromTabW = _tabWCtrl.value;
                  final fromLeft = _searchLeftCtrl.value;
                  final fromSearchW = _searchWCtrl.value;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final spring = widget.springDescription ??
                        FrostedSearchableBottomBar._kSpring;
                    if (retarget.tabW) {
                      _tabWCtrl.animateWith(
                        FrostedSearchableBottomBarController.makeSpring(
                          spring: spring,
                          from: fromTabW,
                          to: targetTabW,
                        ),
                      );
                    }
                    if (retarget.searchLeft) {
                      _searchLeftCtrl.animateWith(
                        FrostedSearchableBottomBarController.makeSpring(
                          spring: spring,
                          from: fromLeft,
                          to: targetSearchLeft,
                        ),
                      );
                    }
                    if (retarget.searchW) {
                      _searchWCtrl.animateWith(
                        FrostedSearchableBottomBarController.makeSpring(
                          spring: spring,
                          from: fromSearchW,
                          to: targetSearchW,
                        ),
                      );
                    }
                  });
                }
                if (totalW != _controller.cachedTotalW) {
                  _controller.cachedTotalW = totalW;
                }
              }

              final curTabW = (_controller.pillsInitialized
                      ? _tabWCtrl.value
                      : targetTabW)
                  .clamp(0.0, totalW);
              final curTabLeft = centeredTab
                  ? ((maxTabW - curTabW) / 2).clamp(0.0, maxTabW)
                  : 0.0;
              final curSearchLeft = (_controller.pillsInitialized
                      ? _searchLeftCtrl.value
                      : targetSearchLeft)
                  .clamp(0.0, totalW);
              final curSearchW = (_controller.pillsInitialized
                      ? _searchWCtrl.value
                      : targetSearchW)
                  .clamp(0.0, totalW);
              final floatY = layout.floatY;
              final totalH = animH + floatY;

              return SizedBox(
                width: totalW,
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: curSearchLeft,
                      bottom: floatY,
                      width: math.max(0.01, curSearchW),
                      height: animH,
                      child: FrostedSearchPill(
                        config: widget.searchConfig,
                        isActive: searching,
                        barBorderRadius: widget.barBorderRadius,
                        onFocusChanged: (focused) {
                          if (focused) {
                            _controller.onFocusChanged(true);
                          } else {
                            _onFocusLost();
                          }
                          widget.searchConfig.onSearchFocusChanged?.call(focused);
                        },
                      ),
                    ),
                    Positioned(
                      left: curTabLeft,
                      bottom: 0,
                      width: math.max(0.01, curTabW),
                      height: animH,
                      child: FrostedTabIndicator(
                        visible: widget.showIndicator && !searching,
                        tabIndex: widget.selectedIndex,
                        onTabChanged: widget.onTabSelected,
                        barHeight: animH,
                        barBorderRadius: widget.barBorderRadius,
                        tabPadding: widget.tabPadding,
                        indicatorColor: widget.indicatorColor,
                        indicatorExpansion: widget.indicatorExpansion,
                        isSearchActive: searching,
                        onDismissSearch: () =>
                            widget.searchConfig.onSearchToggle(false),
                        tabs: widget.tabs,
                        selectedIconColor: resolvedSelectedIconColor,
                        unselectedIconColor: resolvedUnselectedIconColor,
                        iconSize: widget.iconSize,
                        labelFontSize: widget.labelFontSize,
                        textStyle: widget.textStyle,
                        iconLabelSpacing: widget.iconLabelSpacing,
                        collapsedLogoBuilder:
                            widget.searchConfig.collapsedLogoBuilder ??
                                (context) {
                                  final currentTab =
                                      widget.tabs[widget.selectedIndex];
                                  return Center(
                                    child: IconTheme(
                                      data: IconThemeData(
                                        color: widget.unselectedIconColor,
                                        size: widget.iconSize,
                                      ),
                                      child: currentTab.activeIcon ??
                                          currentTab.icon,
                                    ),
                                  );
                                },
                      ),
                    ),
                    if (hasDismiss && dismissVisible)
                      Positioned(
                        right: 0,
                        bottom: floatY,
                        width: animH,
                        height: animH,
                        child: FrostedDismissPill(
                          onTap: () {
                            widget.searchConfig.onCancelTap?.call();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          pillSize: animH,
                          barBorderRadius: widget.barBorderRadius,
                          cancelButtonColor:
                              widget.searchConfig.cancelButtonColor,
                          cancelIcon: widget.searchConfig.cancelIcon,
                          cancelIconSize: widget.searchConfig.cancelIconSize,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (widget.onBarTap == null) return barContent;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onBarTap,
      child: barContent,
    );
  }
}
