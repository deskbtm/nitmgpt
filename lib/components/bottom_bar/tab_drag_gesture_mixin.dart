import 'package:flutter/widgets.dart';

import 'draggable_indicator_physics.dart';

mixin TabDragGestureMixin<T extends StatefulWidget> on State<T> {
  int get tabCount;
  int get tabIndex;
  void notifyTabChanged(int index);

  bool tabIsDown = false;
  bool tabIsDragging = false;
  double tabXAlign = 0.0;
  double barSwayOffset = 0.0;

  static const double _maxSwayPx = 0.75;
  static const double _swayScale = 0.08;
  static const double _swayVelocityThreshold = 4.0;

  @override
  void initState() {
    super.initState();
    tabXAlign = computeTabAlignment(tabIndex);
  }

  void updateTabAlignIfNeeded(int oldTabIndex, int oldTabCount) {
    if (oldTabIndex != tabIndex || oldTabCount != tabCount) {
      if (mounted) setState(() => tabXAlign = computeTabAlignment(tabIndex));
    }
  }

  double computeTabAlignment(int index) =>
      DraggableIndicatorPhysics.computeAlignment(index, tabCount);

  double alignmentFromGlobal(Offset globalPosition) =>
      DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
        globalPosition,
        context,
        tabCount,
      );

  void onBarDragDown(DragDownDetails details) {
    if (!mounted) return;
    setState(() => tabIsDown = true);
  }

  void onBarDragStart(DragStartDetails details) {
    if (!mounted) return;
    setState(() {
      tabIsDragging = true;
      tabXAlign = alignmentFromGlobal(details.globalPosition);
    });
  }

  void onBarDragUpdate(DragUpdateDetails details) {
    if (!mounted) return;
    setState(() {
      tabIsDragging = true;
      tabXAlign = alignmentFromGlobal(details.globalPosition);
      if (details.delta.dx.abs() > _swayVelocityThreshold) {
        barSwayOffset =
            (details.delta.dx * _swayScale).clamp(-_maxSwayPx, _maxSwayPx);
      } else {
        barSwayOffset = 0.0;
      }
    });
  }

  void onBarDragEnd(DragEndDetails details) {
    final relX = (tabXAlign + 1) / 2;
    final positionIndex =
        (relX * (tabCount - 1)).round().clamp(0, tabCount - 1);

    final box = context.findRenderObject()! as RenderBox;
    final rawVelX = details.velocity.pixelsPerSecond.dx / box.size.width;
    const velocityThreshold = 0.5;
    var target = positionIndex;
    if (rawVelX > velocityThreshold && positionIndex < tabCount - 1) {
      target = positionIndex + 1;
    } else if (rawVelX < -velocityThreshold && positionIndex > 0) {
      target = positionIndex - 1;
    }

    if (!mounted) return;
    setState(() {
      tabIsDragging = false;
      tabIsDown = false;
      tabXAlign = computeTabAlignment(target);
      barSwayOffset = 0.0;
    });
    notifyTabChanged(target);
  }

  void onBarDragCancel() {
    if (tabIsDragging) {
      final relX = (tabXAlign + 1) / 2;
      final target = (relX * (tabCount - 1)).round().clamp(0, tabCount - 1);
      if (!mounted) return;
      setState(() {
        tabIsDragging = false;
        tabIsDown = false;
        tabXAlign = computeTabAlignment(target);
        barSwayOffset = 0.0;
      });
      notifyTabChanged(target);
    } else if (mounted) {
      setState(() => tabXAlign = computeTabAlignment(tabIndex));
    }
  }

  void onBarTapDown(TapDownDetails details) {
    final alignment = alignmentFromGlobal(details.globalPosition);
    final relX = (alignment + 1) / 2;
    final index = (relX * tabCount).floor().clamp(0, tabCount - 1);
    notifyTabChanged(index);
  }
}
