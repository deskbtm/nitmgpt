import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nitmgpt/core/frosted_glass_capture.dart';

/// Snapshot-based frosted glass — blurs the bubble layer at low frequency,
/// independent of list scroll (no [BackdropFilter] on list items).
///
/// Stack order: [AppGlassBackground] → [FrostedGlassLayer] → content.
class FrostedGlassLayer extends StatefulWidget {
  const FrostedGlassLayer({
    super.key,
    required this.sourceKey,
    this.config,
  });

  final GlobalKey sourceKey;
  final FrostedGlassCaptureConfig? config;

  @override
  State<FrostedGlassLayer> createState() => _FrostedGlassLayerState();
}

class _FrostedGlassLayerState extends State<FrostedGlassLayer> {
  final _snapshot = ValueNotifier<ui.Image?>(null);
  Timer? _timer;
  bool _capturing = false;
  FrostedGlassCaptureConfig? _config;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _config = widget.config ?? FrostedGlassCaptureConfig.resolve(context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleCaptureLoop();
      _captureOnce();
    });
  }

  void _scheduleCaptureLoop() {
    _timer?.cancel();
    final interval =
        _config?.captureInterval ?? FrostedGlassCaptureConfig.mid.captureInterval;
    _timer = Timer.periodic(interval, (_) => _captureOnce());
  }

  Future<void> _captureOnce() async {
    if (_capturing || !mounted) return;

    final boundary = widget.sourceKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.attached ||
        boundary.size.isEmpty) {
      return;
    }

    _capturing = true;
    try {
      final pixelRatio = _config?.capturePixelRatio ??
          FrostedGlassCaptureConfig.mid.capturePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      if (!mounted) {
        image.dispose();
        return;
      }
      final previous = _snapshot.value;
      _snapshot.value = image;
      previous?.dispose();
    } catch (e, st) {
      assert(() {
        debugPrint('FrostedGlassLayer capture failed: $e\n$st');
        return true;
      }());
    } finally {
      _capturing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _snapshot.value?.dispose();
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _config ?? FrostedGlassCaptureConfig.resolve(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.matrix(
                _saturationMatrix(config.saturation),
              ),
              child: CustomPaint(
                painter: _SnapshotBlurPainter(
                  snapshot: _snapshot,
                  blurSigma: config.blurSigma,
                ),
                size: Size.infinite,
              ),
            ),
            ColoredBox(color: config.tintColor(isDark: isDark)),
          ],
        ),
      ),
    );
  }
}

class _SnapshotBlurPainter extends CustomPainter {
  _SnapshotBlurPainter({
    required ValueNotifier<ui.Image?> snapshot,
    required this.blurSigma,
  })  : _snapshot = snapshot,
        super(repaint: snapshot);

  final ValueNotifier<ui.Image?> _snapshot;
  final double blurSigma;
  final Paint _paint = Paint()..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final image = _snapshot.value;
    if (image == null) {
      return;
    }

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    _paint.imageFilter = ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
    canvas.drawImageRect(image, src, Offset.zero & size, _paint);
    _paint.imageFilter = null;
  }

  @override
  bool shouldRepaint(covariant _SnapshotBlurPainter oldDelegate) {
    return oldDelegate.blurSigma != blurSigma;
  }
}

List<double> _saturationMatrix(double saturation) {
  const lumR = 0.2126;
  const lumG = 0.7152;
  const lumB = 0.0722;
  final inv = 1 - saturation;
  final r = lumR * inv;
  final g = lumG * inv;
  final b = lumB * inv;
  return [
    r + saturation, g, b, 0, 0,
    r, g + saturation, b, 0, 0,
    r, g, b + saturation, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
