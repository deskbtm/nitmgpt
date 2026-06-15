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

/// Opaque tab page shell — app bar + body column inside the root scaffold.
class TabPageShell extends StatelessWidget {
  const TabPageShell({
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
