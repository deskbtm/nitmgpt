import 'package:flutter/material.dart';

export 'package:nitmgpt/components/app_background.dart' show kAppGlassBackground;

var primaryColor = const Color(0xFF74AA9C);

/// Shared corner radius for tiles, grouped lists, and modal sheets.
const kTileBorderRadius = 24.0;
const kTileBorderRadiusAll =
    BorderRadius.all(Radius.circular(kTileBorderRadius));
const kTileTopBorderRadius =
    BorderRadius.vertical(top: Radius.circular(kTileBorderRadius));

ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: primaryColor,
  scaffoldBackgroundColor: Colors.transparent,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 3),
);

/// White mist frosted fill for grouped list tiles on scrollable pages.
Color tileFrostFillColor({required bool isDark}) {
  return isDark ? const Color(0xCC2C2C2E) : const Color(0xD9FFFFFF);
}

Color tileFrostBorderColor({required bool isDark}) {
  return Colors.white.withValues(alpha: isDark ? 0.12 : 0.5);
}

/// Frosted fill for the floating bottom navigation bar.
Color bottomBarFrostFillColor({required bool isDark}) {
  return isDark ? const Color(0xAA1C1C1E) : const Color(0x66FFFFFF);
}

Color bottomBarFrostBorderColor({required bool isDark}) {
  return Colors.white.withValues(alpha: isDark ? 0.12 : 0.45);
}

List<BoxShadow> bottomBarFrostShadows({required bool isDark}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Draggable tab indicator tint on the frosted bar.
Color bottomBarIndicatorFrostColor({required bool isDark, Color? override}) {
  if (override != null) return override;
  return isDark ? const Color(0x33FFFFFF) : const Color(0x55FFFFFF);
}

/// Barely visible elevation for grouped settings tiles.
List<BoxShadow> tileFrostShadows({required bool isDark}) {
  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.07 : 0.022),
      blurRadius: 5,
      offset: const Offset(0, 1),
    ),
  ];
}

/// Horizontal inset of the floating bottom bar from screen edges (iOS 26 HIG).
const kBottomBarHorizontalPadding = 21.0;

/// Vertical padding around the bottom bar in [IndexPage] — keep in sync.
const kBottomBarVerticalPadding = 8.0;

/// Default bottom bar height used in [IndexPage] (iOS 26 tab bar ~62pt).
const kBottomBarHeight = 62.0;

/// Extra scroll gap so the last list row clears the floating bar edge.
const kBottomBarScrollGap = 12.0;

/// Total layout height of [IndexPage]'s bottom bar — keep in sync with
/// [_IndexPageState._buildBottomBar] (bar + vertical padding + safe area).
double tabBottomBarLayoutHeight(BuildContext context) {
  return kBottomBarHeight +
      (kBottomBarVerticalPadding * 2) +
      MediaQuery.paddingOf(context).bottom;
}

/// Opaque tab page shell — scrollable body inside the root scaffold.
class TabPageShell extends StatelessWidget {
  const TabPageShell({
    super.key,
    this.appBar,
    required this.body,
  });

  final Widget? appBar;
  final Widget body;

  /// Top inset for tab pages with a scrollable large title (no back button).
  static double scrollTopPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 12;
  }

  /// Bottom inset for scrollable tab pages above [IndexPage]'s bottom bar.
  static double scrollBottomPadding(BuildContext context) =>
      tabBottomBarLayoutHeight(context) + kBottomBarScrollGap;

  @override
  Widget build(BuildContext context) {
    if (appBar == null) {
      return body;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(bottom: false, child: appBar!),
        Expanded(child: body),
      ],
    );
  }
}
