import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

import 'bar_layout_utils.dart';
import 'bottom_bar_models.dart';

@immutable
class SearchablePillLayout {
  const SearchablePillLayout({
    required this.targetTabW,
    required this.targetSearchLeft,
    required this.targetSearchW,
    required this.floatY,
    required this.extraTargetW,
    required this.dismissReserve,
  });

  final double targetTabW;
  final double targetSearchLeft;
  final double targetSearchW;
  final double floatY;
  final double extraTargetW;
  final double dismissReserve;
}

@immutable
class SpringRetarget {
  const SpringRetarget({
    required this.tabW,
    required this.searchLeft,
    required this.searchW,
  });

  static const none = SpringRetarget(
    tabW: false,
    searchLeft: false,
    searchW: false,
  );

  final bool tabW;
  final bool searchLeft;
  final bool searchW;

  bool get any => tabW || searchLeft || searchW;
}

class FrostedSearchableBottomBarController extends ChangeNotifier {
  bool _searchFocused = false;
  bool get searchFocused => _searchFocused;

  bool _pillsInitialized = false;
  bool _pillsInitScheduled = false;
  bool get pillsInitialized => _pillsInitialized;
  bool get pillsInitScheduled => _pillsInitScheduled;

  bool _isSearchOpen = false;
  bool get isSearchOpen => _isSearchOpen;

  double _prevTabWTarget = double.nan;
  double _prevSearchLeftTarget = double.nan;
  double _prevSearchWTarget = double.nan;
  double cachedTotalW = 0;

  void openSearch() {
    if (_isSearchOpen) return;
    _isSearchOpen = true;
    notifyListeners();
  }

  void closeSearch() {
    if (!_isSearchOpen) return;
    _isSearchOpen = false;
    if (_searchFocused) _searchFocused = false;
    notifyListeners();
  }

  void syncSearchActive(bool isActive) {
    if (_isSearchOpen == isActive) return;
    _isSearchOpen = isActive;
  }

  void onFocusChanged(bool focused) {
    if (_searchFocused == focused) return;
    _searchFocused = focused;
    notifyListeners();
  }

  void onSearchActiveChanged({
    required bool wasActive,
    required bool isActive,
  }) {
    if (wasActive && !isActive && _searchFocused) {
      _searchFocused = false;
      notifyListeners();
    }
  }

  void markInitScheduled({required double totalW}) {
    _pillsInitScheduled = true;
    cachedTotalW = totalW;
  }

  void initializePills({
    required double tabW,
    required double searchLeft,
    required double searchW,
  }) {
    _prevTabWTarget = tabW;
    _prevSearchLeftTarget = searchLeft;
    _prevSearchWTarget = searchW;
    _pillsInitialized = true;
    _pillsInitScheduled = false;
    notifyListeners();
  }

  SearchablePillLayout computeLayout({
    required double totalW,
    required bool searching,
    required bool expandWhenActive,
    required double barHeight,
    required double searchBarHeight,
    required double spacing,
    required bool hasDismiss,
    required bool dismissVisible,
    required double? collapsedTabWidth,
    required TabPillAnchor tabPillAnchor,
    required double extraFullW,
    required ExtraButtonPosition extraPos,
    required bool extraCollapsesOnSearch,
    required bool isKeyboardActive,
    required double keyboardH,
    required int tabCount,
    required double? perTabWidth,
  }) {
    final targetH = searching ? searchBarHeight : barHeight;

    final extraTargetW = extraFullW > 0
        ? (searching ? math.min(extraFullW, targetH) : extraFullW)
        : 0.0;

    final extraWLeft =
        (extraFullW > 0 && extraPos == ExtraButtonPosition.beforeSearch)
            ? (extraTargetW + spacing)
            : 0.0;
    final extraWRight =
        (extraFullW > 0 && extraPos == ExtraButtonPosition.afterSearch)
            ? (extraTargetW + spacing)
            : 0.0;
    final extraFullWLeft =
        (extraFullW > 0 && extraPos == ExtraButtonPosition.beforeSearch)
            ? (extraFullW + spacing)
            : 0.0;
    final extraFullWRight =
        (extraFullW > 0 && extraPos == ExtraButtonPosition.afterSearch)
            ? (extraFullW + spacing)
            : 0.0;

    final doCollapseLayout = isKeyboardActive && extraCollapsesOnSearch;
    final curExtraWLeft = doCollapseLayout ? 0.0 : extraWLeft;
    final curExtraWRight = doCollapseLayout ? 0.0 : extraWRight;

    final targetCompactW = targetH;
    final dismissReserve = hasDismiss ? (targetH + spacing) : 0.0;

    final maxTabW =
        totalW - targetCompactW - spacing - extraFullWLeft - extraFullWRight;

    final naturalTabW = resolveTabPillWidth(
      tabWidth: perTabWidth,
      tabCount: tabCount,
      maxAvailable: maxTabW,
    );

    final targetTabW =
        !searching ? naturalTabW : (collapsedTabWidth ?? targetH);

    final centeredTab = tabPillAnchor == TabPillAnchor.center;

    final targetSearchLeft = !searching || !expandWhenActive
        ? totalW - targetCompactW - extraWRight
        : isKeyboardActive
            ? curExtraWLeft
            : centeredTab
                ? (maxTabW + targetTabW) / 2 + curExtraWLeft + spacing
                : targetTabW + curExtraWLeft + spacing;

    final targetSearchW = !searching || !expandWhenActive
        ? targetCompactW
        : totalW -
            targetSearchLeft -
            curExtraWRight -
            (dismissVisible ? dismissReserve : 0.0);

    final floatY = (_searchFocused && keyboardH > 0) ? keyboardH : 0.0;

    return SearchablePillLayout(
      targetTabW: targetTabW,
      targetSearchLeft: targetSearchLeft,
      targetSearchW: targetSearchW,
      floatY: floatY,
      extraTargetW: extraTargetW,
      dismissReserve: dismissReserve,
    );
  }

  SpringRetarget checkRetarget(SearchablePillLayout layout) {
    final newTabW = layout.targetTabW != _prevTabWTarget;
    final newLeft = layout.targetSearchLeft != _prevSearchLeftTarget;
    final newSearchW = layout.targetSearchW != _prevSearchWTarget;

    if (newTabW) _prevTabWTarget = layout.targetTabW;
    if (newLeft) _prevSearchLeftTarget = layout.targetSearchLeft;
    if (newSearchW) _prevSearchWTarget = layout.targetSearchW;

    return SpringRetarget(
      tabW: newTabW,
      searchLeft: newLeft,
      searchW: newSearchW,
    );
  }

  static SpringSimulation makeSpring({
    required SpringDescription spring,
    required double from,
    required double to,
  }) =>
      SpringSimulation(spring, from, to, 0.0);
}
