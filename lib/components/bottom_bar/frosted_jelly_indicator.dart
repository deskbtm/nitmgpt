import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';

import 'draggable_indicator_physics.dart';

/// Vertical bleed room so the jelly droplet can bulge past the bar on press.
double bottomBarJellyOverflow(double expansion) => expansion + 6;

/// Sliding jelly droplet behind tab icons — morphs to an oval on press/drag.
class FrostedJellyIndicator extends StatelessWidget {
  const FrostedJellyIndicator({
    super.key,
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.velocity,
    required this.indicatorColor,
    required this.borderRadius,
    this.expansion = 14,
    this.padding = const EdgeInsets.all(4),
  });

  final int itemCount;
  final Alignment alignment;
  final double thickness;
  final double velocity;
  final Color indicatorColor;
  final double borderRadius;
  final double expansion;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = thickness.clamp(0.0, 1.0);
    final horizontalBleed = expansion * t * 0.65;
    final verticalBleed = expansion * t * 1.35;
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      RelativeRect.fromLTRB(
        -horizontalBleed,
        -verticalBleed,
        -horizontalBleed,
        -verticalBleed,
      ),
      t,
    )!;

    final dragOpacity = t;
    final restingOpacity = (1.0 - (t / 0.15)).clamp(0.0, 1.0);
    final opacity = restingOpacity > 0.05 ? restingOpacity : dragOpacity;

    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: FractionallySizedBox(
          widthFactor: 1 / itemCount,
          alignment: alignment,
          child: Transform(
            alignment: Alignment.center,
            transform: DraggableIndicatorPhysics.buildJellyTransform(
              velocity: Offset(velocity, 0),
              maxDistortion: 0.8,
              velocityScale: 10,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fromRelativeRect(
                  rect: rect,
                  child: Opacity(
                    opacity: opacity,
                    child: _JellyIndicatorShape(
                      color: indicatorColor,
                      borderRadius: borderRadius,
                      thickness: t,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resting: rounded rect. Press/drag: morphs into a vertical oval droplet.
class _JellyIndicatorShape extends StatelessWidget {
  const _JellyIndicatorShape({
    required this.color,
    required this.borderRadius,
    required this.thickness,
  });

  final Color color;
  final double borderRadius;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    if (thickness > 0.98) {
      return ClipOval(
        child: ColoredBox(color: color, child: const SizedBox.expand()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final radiusX = lerpDouble(borderRadius, width / 2, thickness)!;
        final radiusY = lerpDouble(borderRadius, height / 2, thickness)!;
        final corner = Radius.elliptical(radiusX, radiusY);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: corner,
              topRight: corner,
              bottomLeft: corner,
              bottomRight: corner,
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
