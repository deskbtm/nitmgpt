import 'dart:ui';

/// Shared frosted-glass blur for [BackdropFilter] widgets (back button, tiles).
///
/// Reusing one [ImageFilter] avoids allocating a new native blur kernel on every
/// rebuild while keeping the same visual sigma.
final ImageFilter kFrostedGlassBlurFilter = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

const double kFrostedGlassBlurSigma = 12;
