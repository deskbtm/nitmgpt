import 'package:flutter/widgets.dart';

/// Shared physics utilities for draggable bottom bar indicators.
class DraggableIndicatorPhysics {
  DraggableIndicatorPhysics._();

  static double applyRubberBandResistance(
    double value, {
    double resistance = 0.4,
    double maxOverdrag = 0.3,
  }) {
    if (value < 0) {
      final overdrag = -value;
      final resistedOverdrag = overdrag * resistance;
      return -resistedOverdrag.clamp(0.0, maxOverdrag);
    }
    if (value > 1) {
      final overdrag = value - 1;
      final resistedOverdrag = overdrag * resistance;
      return 1 + resistedOverdrag.clamp(0.0, maxOverdrag);
    }
    return value;
  }

  static double computeAlignment(int index, int itemCount) {
    if (itemCount <= 1) return 0;
    final relativeIndex = (index / (itemCount - 1)).clamp(0.0, 1.0);
    return (relativeIndex * 2) - 1;
  }

  static double getAlignmentFromGlobalPosition(
    Offset globalPosition,
    BuildContext context,
    int itemCount,
  ) {
    final box = context.findRenderObject()! as RenderBox;
    final localPosition = box.globalToLocal(globalPosition);
    final indicatorWidth = 1.0 / itemCount;
    final draggableRange = 1.0 - indicatorWidth;
    final padding = indicatorWidth / 2;
    final rawRelativeX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
    final normalizedX = (rawRelativeX - padding) / draggableRange;
    final adjustedRelativeX = applyRubberBandResistance(normalizedX);
    return (adjustedRelativeX * 2) - 1;
  }

  static Matrix4 buildJellyTransform({
    required Offset velocity,
    double maxDistortion = 0.7,
    double velocityScale = 1000.0,
  }) {
    final speed = velocity.distance;
    if (speed == 0 || !speed.isFinite) {
      return Matrix4.identity()..translate(0.0001, 0.0);
    }

    final direction = velocity / speed;
    final distortionFactor =
        (speed / velocityScale).clamp(0.0, 1.0) * maxDistortion;
    final squashX = 1.0 - (direction.dx.abs() * distortionFactor * 0.5);
    final squashY = 1.0 - (direction.dy.abs() * distortionFactor * 0.5);
    final stretchX = 1.0 + (direction.dy.abs() * distortionFactor * 0.3);
    final stretchY = 1.0 + (direction.dx.abs() * distortionFactor * 0.3);
    final scaleX = squashX * stretchX;
    final scaleY = squashY * stretchY;

    final matrix = Matrix4.identity()..scale(scaleX, scaleY);
    if (matrix.isIdentity()) {
      matrix.translate(0.0001, 0.0);
    }
    return matrix;
  }
}
