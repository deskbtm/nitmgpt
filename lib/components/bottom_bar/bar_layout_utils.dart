import 'dart:math' as math;

/// Resolves the effective tab pill width given a per-slot [tabWidth].
double resolveTabPillWidth({
  required double? tabWidth,
  required int tabCount,
  required double maxAvailable,
}) {
  final safeMax = math.max(0.0, maxAvailable);
  if (tabWidth == null) return safeMax;
  return (tabWidth * tabCount).clamp(0.0, safeMax);
}
