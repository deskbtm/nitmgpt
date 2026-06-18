import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

export 'components/app_background.dart' show kAppGlassBackground;

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

/// iOS 26-style bottom bar glass — matches library [kBottomBarGlassDefaults].
LiquidGlassSettings bottomBarGlassSettings({required bool isDark}) {
  if (isDark) {
    return const LiquidGlassSettings(
      glassColor: Color(0xAA1C1C1E),
      thickness: 30,
      blur: 3,
      chromaticAberration: 0.3,
      lightIntensity: 0.6,
      refractiveIndex: 1.59,
      saturation: 0.7,
      ambientStrength: 1,
      lightAngle: GlassDefaults.lightAngle,
    );
  }

  return const LiquidGlassSettings(
    glassColor: Color(0x3DFFFFFF),
    thickness: 30,
    blur: 3,
    chromaticAberration: 0.3,
    lightIntensity: 0.6,
    refractiveIndex: 1.59,
    saturation: 0.7,
    ambientStrength: 1,
    lightAngle: GlassDefaults.lightAngle,
  );
}

/// Draggable tab indicator — keep translucent so refraction stays visible.
LiquidGlassSettings bottomBarIndicatorGlassSettings({required bool isDark}) {
  return LiquidGlassSettings(
    glassColor: isDark ? const Color(0x1AFFFFFF) : const Color(0x33FFFFFF),
    thickness: 20,
    blur: 2,
    chromaticAberration: 0.3,
    lightIntensity: 1.6,
    refractiveIndex: 1.15,
    saturation: 1.2,
    ambientStrength: 1,
    lightAngle: GlassDefaults.lightAngle,
  );
}

final GlassThemeData glassThemeData = GlassThemeData.simple(
  blur: 6,
  thickness: 24,
  quality: GlassQuality.standard,
);

/// White mist frosted glass for grouped list tiles on scrollable pages.
LiquidGlassSettings tileGlassSettings({required bool isDark}) {
  if (isDark) {
    return const LiquidGlassSettings(
      glassColor: Color(0xCC2C2C2E),
      thickness: 26,
      blur: 6,
      chromaticAberration: 0.2,
      lightIntensity: 0.55,
      refractiveIndex: 1.52,
      saturation: 0.75,
      ambientStrength: 1,
      lightAngle: GlassDefaults.lightAngle,
    );
  }

  return const LiquidGlassSettings(
    glassColor: Color(0xD9FFFFFF),
    thickness: 26,
    blur: 6,
    chromaticAberration: 0.2,
    lightIntensity: 0.85,
    refractiveIndex: 1.52,
    saturation: 0.9,
    ambientStrength: 1,
    lightAngle: GlassDefaults.lightAngle,
  );
}

/// Horizontal inset of the floating bottom bar from screen edges (iOS 26 HIG).
const kBottomBarHorizontalPadding = 21.0;

/// Vertical padding around [GlassBottomBar] in [IndexPage] — keep in sync.
const kBottomBarVerticalPadding = 8.0;

/// Default [GlassBottomBar.barHeight] used in [IndexPage] (iOS 26 tab bar ~62pt).
const kBottomBarHeight = 62.0;

/// Extra scroll gap so the last list row clears the floating glass bar edge.
const kBottomBarScrollGap = 12.0;

/// Total layout height of [IndexPage]'s glass bottom bar — keep in sync with
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

  /// Bottom inset for scrollable tab pages above [IndexPage]'s glass bottom bar.
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
