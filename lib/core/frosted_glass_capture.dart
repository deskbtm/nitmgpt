import 'package:flutter/material.dart';

/// Tunables for the snapshot-based frosted glass layer (not [BackdropFilter]).
class FrostedGlassCaptureConfig {
  const FrostedGlassCaptureConfig({
    required this.captureInterval,
    required this.capturePixelRatio,
    required this.blurSigma,
    required this.tintOpacity,
    required this.saturation,
  });

  /// Time between background snapshots (~fps = 1000 / ms).
  final Duration captureInterval;

  /// `toImage` pixel ratio — lower = stronger downsample (~1/4 at 0.25).
  final double capturePixelRatio;

  final double blurSigma;
  final double tintOpacity;
  final double saturation;

  static const high = FrostedGlassCaptureConfig(
    captureInterval: Duration(milliseconds: 33),
    capturePixelRatio: 0.32,
    blurSigma: 20,
    tintOpacity: 0.74,
    saturation: 1.1,
  );

  static const mid = FrostedGlassCaptureConfig(
    captureInterval: Duration(milliseconds: 50),
    capturePixelRatio: 0.26,
    blurSigma: 16,
    tintOpacity: 0.76,
    saturation: 1.08,
  );

  static const low = FrostedGlassCaptureConfig(
    captureInterval: Duration(milliseconds: 66),
    capturePixelRatio: 0.18,
    blurSigma: 12,
    tintOpacity: 0.78,
    saturation: 1.05,
  );

  /// Pick a tier from screen size / density.
  static FrostedGlassCaptureConfig resolve(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (shortest >= 400 && dpr >= 2.5) return high;
    if (shortest >= 360) return mid;
    return low;
  }

  Color tintColor({required bool isDark}) {
    return isDark
        ? Colors.black.withValues(alpha: tintOpacity * 0.55)
        : Colors.white.withValues(alpha: tintOpacity);
  }
}
