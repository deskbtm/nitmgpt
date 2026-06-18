import 'dart:ui';

/// Shared frosted-glass blur for [BackdropFilter] widgets (back button, tiles).
///
/// Reusing one [ImageFilter] avoids allocating a new native blur kernel on every
/// rebuild while keeping the same visual sigma.
final ImageFilter kFrostedGlassBlurFilter = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

const double kFrostedGlassBlurSigma = 12;

/// Lighter blur for grouped settings tiles.
final ImageFilter kTileFrostBlurFilter = ImageFilter.blur(sigmaX: 6, sigmaY: 6);

const double kTileFrostBlurSigma = 6;

/// Bottom navigation bar frosted blur.
final ImageFilter kBottomBarFrostBlurFilter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

const double kBottomBarFrostBlurSigma = 8;
