import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Soft mint wallpaper base behind frosted UI.
const kAppWallpaperMint = Color(0xFFF2FAF8);

/// Full-screen wallpaper — light mint fill + flat rising bubbles.
const Widget kAppGlassBackground = RepaintBoundary(
  child: AppGlassBackground(),
);

/// Extra margin before culling — release as soon as fully off-screen.
const _kOffScreenCull = 12.0;

/// Wallpaper layer only: light mint fill + flat rising bubbles.
///
/// Sits **behind** [Scaffold] body and bottom bar (see [IndexPage] Stack).
/// Pass [pauseListenable] to stop animation while lists scroll (saves GPU).
class AppGlassBackground extends StatefulWidget {
  const AppGlassBackground({super.key, this.pauseListenable});

  /// When `true`, physics and repaint are paused (e.g. during scroll).
  final ValueListenable<bool>? pauseListenable;

  @override
  State<AppGlassBackground> createState() => _AppGlassBackgroundState();
}

class _AppGlassBackgroundState extends State<AppGlassBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _BubbleField _bubbleField = _BubbleField();
  final _repaint = ValueNotifier<int>(0);
  Duration _lastElapsed = Duration.zero;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.pauseListenable?.addListener(_onPauseChanged);
    _paused = widget.pauseListenable?.value ?? false;
    if (!_paused) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant AppGlassBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pauseListenable != widget.pauseListenable) {
      oldWidget.pauseListenable?.removeListener(_onPauseChanged);
      widget.pauseListenable?.addListener(_onPauseChanged);
      _applyPaused(widget.pauseListenable?.value ?? false);
    }
  }

  void _onPauseChanged() {
    _applyPaused(widget.pauseListenable?.value ?? false);
  }

  void _applyPaused(bool paused) {
    if (paused == _paused) {
      return;
    }
    _paused = paused;
    if (paused) {
      _ticker.stop();
    } else {
      _lastElapsed = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_paused) {
      return;
    }

    final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
    _lastElapsed = elapsed;
    if (dt <= 0 || dt > 0.05) {
      return;
    }

    final size = _bubbleField.lastSize;
    if (size == null) {
      return;
    }

    if (_bubbleField.tick(dt, size)) {
      _repaint.value++;
    }
  }

  @override
  void dispose() {
    widget.pauseListenable?.removeListener(_onPauseChanged);
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: ColoredBox(
          color: kAppWallpaperMint,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.biggest;
              if (size.isEmpty) {
                return const SizedBox.shrink();
              }
              _bubbleField.ensurePopulated(size);

              return CustomPaint(
                painter: _FlatBubblePainter(
                  _bubbleField.slots,
                  repaint: _repaint,
                ),
                size: size,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Theme mint tones — flat fill only.
class _BubblePalette {
  static const light = Color(0xFFD6ECE6);
  static const mid = Color(0xFFC4E1DA);
  static const deep = Color(0xFFBADAD3);
  static const accent = Color(0xFF70A697);
  static const shadow = Color(0xFFB1D6CC);

  static const tones = [shadow, deep, mid, light, accent];
  static const tierRadii = [8.0, 17.0, 27.0, 38.0];
  static const tierCount = 4;
}

class _Bubble {
  _Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.riseSpeed,
    required this.wobblePhase,
    required this.wobbleAmplitude,
    required this.wobbleSpeed,
    required this.fillColor,
    required this.layer,
  });

  double x;
  double y;
  final double radius;
  final double riseSpeed;
  final double wobblePhase;
  final double wobbleAmplitude;
  final double wobbleSpeed;
  final Color fillColor;
  final int layer;
}

class _BubbleField {
  _BubbleField({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;
  final List<_Bubble?> slots = [];
  final List<double> _respawnIn = [];
  Size? lastSize;

  static const _targetCount = 40;

  void ensurePopulated(Size size) {
    if (lastSize == size &&
        slots.length == _targetCount &&
        _respawnIn.length == _targetCount) {
      return;
    }
    lastSize = size;
    slots
      ..clear()
      ..addAll(
        List.generate(_targetCount, (i) {
          final slot = (i + _random.nextDouble() * 0.7) / _targetCount;
          final y = slot * size.height * 1.12 - size.height * 0.06;
          return _spawnBubble(size, y: y);
        }),
      );
    _respawnIn
      ..clear()
      ..addAll(List.filled(_targetCount, 0.0));
  }

  /// Returns whether any slot changed visually.
  bool tick(double dt, Size size) {
    lastSize = size;
    var changed = false;
    final respawnStagger = _respawnStaggerSeconds(size);

    final slotCount = math.min(slots.length, _respawnIn.length);
    for (var i = 0; i < slotCount; i++) {
      final bubble = slots[i];
      if (bubble == null) {
        _respawnIn[i] -= dt;
        if (_respawnIn[i] <= 0) {
          final layer = _random.nextInt(_BubblePalette.tierCount);
          final radius = _BubblePalette.tierRadii[layer];
          slots[i] = _spawnBubble(
            size,
            y: size.height + radius + 12,
            layer: layer,
          );
          changed = true;
        }
        continue;
      }

      if (!_intersectsViewport(bubble, size)) {
        if (bubble.y + bubble.radius < -_kOffScreenCull ||
            bubble.y - bubble.radius > size.height + _kOffScreenCull) {
          _releaseSlot(i, respawnStagger);
          changed = true;
        }
        continue;
      }

      final accel = bubble.riseSpeed *
          0.18 *
          (1 - (bubble.y / size.height).clamp(0.0, 1.0));
      bubble.y -= (bubble.riseSpeed + accel) * dt;
      bubble.x += math.sin(bubble.wobblePhase + bubble.y * bubble.wobbleSpeed) *
          bubble.wobbleAmplitude *
          dt;
      changed = true;

      if (bubble.y + bubble.radius < -_kOffScreenCull) {
        _releaseSlot(i, respawnStagger);
      }
    }

    return changed;
  }

  void _releaseSlot(int index, double respawnStagger) {
    slots[index] = null;
    _respawnIn[index] = _random.nextDouble() * respawnStagger;
  }

  double _respawnStaggerSeconds(Size size) {
    const avgSpeed = 28.0;
    return (size.height / avgSpeed).clamp(8.0, 36.0);
  }

  _Bubble _spawnBubble(
    Size size, {
    required double y,
    int? layer,
  }) {
    final resolvedLayer = layer ?? _random.nextInt(_BubblePalette.tierCount);
    final radius = _BubblePalette.tierRadii[resolvedLayer];
    final color =
        _BubblePalette.tones[_random.nextInt(_BubblePalette.tones.length)];
    final opacity = 0.20 + _random.nextDouble() * 0.46;

    return _Bubble(
      x: _random.nextDouble() * size.width,
      y: y,
      radius: radius,
      riseSpeed: _riseSpeedForRadius(radius),
      wobblePhase: _random.nextDouble() * math.pi * 2,
      wobbleAmplitude: 8 + (radius / 38) * 14 + _random.nextDouble() * 10,
      wobbleSpeed: 0.012 + _random.nextDouble() * 0.01,
      fillColor: color.withValues(alpha: opacity),
      layer: resolvedLayer,
    );
  }

  static bool _intersectsViewport(_Bubble bubble, Size size) {
    return bubble.y + bubble.radius >= -_kOffScreenCull &&
        bubble.y - bubble.radius <= size.height + _kOffScreenCull &&
        bubble.x + bubble.radius >= -_kOffScreenCull &&
        bubble.x - bubble.radius <= size.width + _kOffScreenCull;
  }

  double _riseSpeedForRadius(double radius) {
    return (58 - radius * 1.35).clamp(14.0, 48.0);
  }
}

class _FlatBubblePainter extends CustomPainter {
  _FlatBubblePainter(this.slots, {required Listenable repaint})
      : super(repaint: repaint);

  final List<_Bubble?> slots;
  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (var layer = 0; layer < _BubblePalette.tierCount; layer++) {
      for (final bubble in slots) {
        if (bubble == null || bubble.layer != layer) continue;
        if (!_BubbleField._intersectsViewport(bubble, size)) continue;
        _paint.color = bubble.fillColor;
        canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlatBubblePainter oldDelegate) => false;
}
