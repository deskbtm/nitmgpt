import 'package:flutter/material.dart';

/// Opens [onActivated] after [requiredTaps] within [resetAfter].
class DeveloperHiddenTapDetector extends StatefulWidget {
  const DeveloperHiddenTapDetector({
    super.key,
    required this.child,
    required this.onActivated,
    this.requiredTaps = 7,
    this.resetAfter = const Duration(seconds: 2),
  });

  final Widget child;
  final VoidCallback onActivated;
  final int requiredTaps;
  final Duration resetAfter;

  @override
  State<DeveloperHiddenTapDetector> createState() =>
      _DeveloperHiddenTapDetectorState();
}

class _DeveloperHiddenTapDetectorState extends State<DeveloperHiddenTapDetector> {
  int _tapCount = 0;
  DateTime? _lastTapAt;

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTapAt == null ||
        now.difference(_lastTapAt!) > widget.resetAfter) {
      _tapCount = 0;
    }
    _lastTapAt = now;
    _tapCount++;
    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      _lastTapAt = null;
      widget.onActivated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
