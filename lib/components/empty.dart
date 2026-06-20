import 'package:flutter/material.dart';
import 'package:nitmgpt/theme/app_theme.dart';

/// Quiet empty-state placeholder for lists with no content yet.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitleText = subtitle;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _EmptyStateOrnament(),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: 0.2,
                color: primaryColor.withValues(alpha: 0.88),
              ),
            ),
            if (subtitleText != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitleText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  letterSpacing: 0.35,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.72),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Minimal mark — a resting point between two quiet strokes.
class _EmptyStateOrnament extends StatelessWidget {
  const _EmptyStateOrnament();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 36,
      child: CustomPaint(
        painter: _EmptyOrnamentPainter(
          color: primaryColor.withValues(alpha: 0.42),
        ),
      ),
    );
  }
}

class _EmptyOrnamentPainter extends CustomPainter {
  const _EmptyOrnamentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final stroke = Paint()
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    stroke.color = color.withValues(alpha: 0.28);
    canvas.drawLine(
      Offset(center.dx - 18, center.dy - 10),
      Offset(center.dx + 6, center.dy - 10),
      stroke,
    );

    canvas.drawCircle(
      center,
      2.4,
      Paint()..color = color.withValues(alpha: 0.55),
    );

    stroke.color = color.withValues(alpha: 0.22);
    canvas.drawLine(
      Offset(center.dx - 8, center.dy + 12),
      Offset(center.dx + 20, center.dy + 12),
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _EmptyOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}
