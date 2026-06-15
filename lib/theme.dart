import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

export 'components/app_background.dart' show kAppGlassBackground;

var primaryColor = const Color(0xFF74AA9C);

ThemeData lightThemeData = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: primaryColor,
  scaffoldBackgroundColor: Colors.transparent,
  floatingActionButtonTheme: const FloatingActionButtonThemeData(elevation: 3),
);

/// Quality for scrollable / grouped content — use opaque widgets instead of glass.
/// See: https://github.com/sdegenaar/liquid_glass_widgets#glass-vs-content--design-philosophy
const GlassQuality contentGlassQuality = GlassQuality.minimal;

/// Quality for toolbars, tab bars, bottom bars, and dialogs (navigation chrome).
const GlassQuality chromeGlassQuality = GlassQuality.standard;

/// Shared layer settings for grouped toolbar controls (one shader pass).
const LiquidGlassSettings toolbarGlassSettings = LiquidGlassSettings(
  blur: 6,
  thickness: 24,
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

/// Lightweight shell for tab pages inside the root [GlassScaffold].
class GlassTabShell extends StatelessWidget {
  const GlassTabShell({
    super.key,
    this.appBar,
    required this.body,
  });

  final Widget? appBar;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (appBar != null) SafeArea(bottom: false, child: appBar!),
        Expanded(child: body),
      ],
    );
  }
}

/// Groups glass controls under a single [AdaptiveLiquidGlassLayer].
class GlassToolbarLayer extends StatelessWidget {
  const GlassToolbarLayer({
    super.key,
    required this.child,
    this.quality = chromeGlassQuality,
  });

  final Widget child;
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLiquidGlassLayer(
      quality: quality,
      settings: toolbarGlassSettings,
      child: child,
    );
  }
}
