import 'package:flutter/material.dart';

/// Reference-matched wallpaper for glass surfaces to refract against.
const Widget kAppGlassBackground = RepaintBoundary(
  child: AppGlassBackground(),
);

class AppGlassBackground extends StatelessWidget {
  const AppGlassBackground({super.key});

  static final _painter = _ReferenceBackgroundPainter();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFC8E4DD),
      child: CustomPaint(
        painter: _painter,
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _ReferenceBackgroundPainter extends CustomPainter {
  _ReferenceBackgroundPainter();

  Size? _cachedSize;
  Path? _cachedWhitePath;

  // Sampled from reference image (473×1024).
  // Mint gradient range sampled from reference bottom block.
  static const Color _mintLight = Color(0xFFDAF0EA);
  static const Color _mintMid = Color(0xFFC8E4DD);
  static const Color _mintDeep = Color(0xFFBEDDD5);
  static const Color _whiteBright = Color(0xFFF4F5FA);
  static const Color _whiteSoft = Color(0xFFF3F3F8);
  static const Color _whiteEdge = Color(0xFFF5F4F7);

  /// Anchor points along the curved off-white / mint boundary.
  static const List<Offset> _whiteBoundary = [
    Offset(0.2368, 0.0000),
    Offset(0.4038, 0.0391),
    Offset(0.6279, 0.0781),
    Offset(0.8499, 0.1172),
    Offset(0.9619, 0.1367),
    Offset(0.9979, 0.1450),
    Offset(0.9979, 0.1641),
    Offset(0.9450, 0.1953),
    Offset(0.8097, 0.2344),
    Offset(0.6744, 0.2734),
    Offset(0.5391, 0.3066),
    Offset(0.4376, 0.3516),
    Offset(0.3340, 0.4180),
    Offset(0.2368, 0.4766),
    Offset(0.1290, 0.5469),
    Offset(0.0465, 0.5996),
    Offset(0.0000, 0.6299),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_mintLight, _mintMid, _mintDeep],
          stops: [0.0, 0.38, 1.0],
        ).createShader(rect),
    );

    _drawMintBottomGlow(canvas, size);

    final whitePath = _whiteOverlayPath(size);
    canvas.drawPath(
      whitePath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_whiteBright, _whiteSoft, _whiteEdge],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(whitePath.getBounds()),
    );
  }

  /// Extra vertical depth for the lower mint block below the white curve.
  void _drawMintBottomGlow(Canvas canvas, Size size) {
    final glowRect = Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.58);
    canvas.drawRect(
      glowRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mintMid.withValues(alpha: 0.0),
            _mintDeep.withValues(alpha: 0.4),
            const Color(0xFFB5D9CF),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(glowRect),
    );
  }

  Path _whiteOverlayPath(Size size) {
    if (_cachedSize == size && _cachedWhitePath != null) {
      return _cachedWhitePath!;
    }

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(_whiteBoundary.first.dx * size.width, 0);

    _appendSmoothSpline(path, _whiteBoundary, size);
    path.close();
    _cachedSize = size;
    _cachedWhitePath = path;
    return path;
  }

  /// Catmull-Rom spline converted to cubic Bezier segments.
  void _appendSmoothSpline(Path path, List<Offset> normalized, Size size) {
    if (normalized.length < 2) {
      return;
    }

    final points = [
      for (final point in normalized)
        Offset(point.dx * size.width, point.dy * size.height),
    ];

    for (var i = 0; i < points.length - 1; i++) {
      final previous = points[i == 0 ? 0 : i - 1];
      final current = points[i];
      final next = points[i + 1];
      final afterNext = points[i + 2 >= points.length ? points.length - 1 : i + 2];

      final control1 = Offset(
        current.dx + (next.dx - previous.dx) / 6,
        current.dy + (next.dy - previous.dy) / 6,
      );
      final control2 = Offset(
        next.dx - (afterNext.dx - current.dx) / 6,
        next.dy - (afterNext.dy - current.dy) / 6,
      );

      path.cubicTo(
        control1.dx,
        control1.dy,
        control2.dx,
        control2.dy,
        next.dx,
        next.dy,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceBackgroundPainter oldDelegate) =>
      false;
}
