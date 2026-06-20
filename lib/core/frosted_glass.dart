import 'dart:ui';

/// Shared [BackdropFilter] blur kernels — reused to avoid per-rebuild allocation.
///
/// Used by the floating bottom bar and secondary-page back button only.
final ImageFilter kFrostedGlassBlurFilter = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

const double kFrostedGlassBlurSigma = 12;

/// Bottom navigation bar frosted blur.
final ImageFilter kBottomBarFrostBlurFilter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

const double kBottomBarFrostBlurSigma = 8;
