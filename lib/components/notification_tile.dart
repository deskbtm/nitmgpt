import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/tile_surface.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/theme/app_theme.dart';
import 'package:unicons/unicons.dart';

class NotificationTitle extends StatelessWidget {
  const NotificationTitle({
    super.key,
    this.title,
    this.icon,
    this.subtitle,
    this.tileKey,
    this.appName,
    this.dateTime,
    this.adProbability = .0,
    this.spamProbability = .0,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.pageStorageId,
  });

  final String? title;
  final String? subtitle;
  final String? appName;
  final String? tileKey;
  final String? dateTime;
  final double? adProbability;
  final double? spamProbability;
  final Uint8List? icon;
  final EdgeInsetsGeometry? margin;
  /// Unique id for [ExpansionTile] page storage — must not share the list
  /// scroll bucket or Flutter reads a scroll offset (double) as bool.
  final String? pageStorageId;

  static const _subtitleStyle = TextStyle(fontSize: 12, color: Colors.black87);
  static const _dateTimeStyle = TextStyle(color: Color.fromARGB(255, 0, 53, 2));
  static const _boldStyle = TextStyle(fontWeight: FontWeight.bold);
  static const _detailSubtitleStyle = TextStyle(fontSize: 12);

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? '';
    final displaySubtitle = subtitle ?? '';
    final adPercent = (adProbability ?? 0) * 100;
    final spamPercent = (spamProbability ?? 0) * 100;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: TileSurface(
        margin: margin,
        fillColor: tileFillColor(isDark: isDark),
        borderColor: tileBorderColor(isDark: isDark),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
          ),
          child: Material(
            color: Colors.transparent,
            child: ExpansionTile(
              key: pageStorageId == null
                  ? null
                  : PageStorageKey<String>('notification-tile-$pageStorageId'),
              tilePadding: const EdgeInsets.only(
                top: 10,
                left: 15,
                right: 15,
                bottom: 7,
              ),
              title: Row(
                children: [
                  SizedBox(
                    width: 23,
                    height: 23,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: AppIconImage(
                        width: 17,
                        height: 17,
                        bytes: icon,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ellipsis(displayTitle),
                  const SizedBox(width: 10),
                  _ellipsis(
                    appName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: RichText(
                  maxLines: 2,
                  text: TextSpan(
                    style: _subtitleStyle,
                    children: [
                      TextSpan(text: dateTime ?? '', style: _dateTimeStyle),
                      const TextSpan(text: ' : '),
                      TextSpan(text: displaySubtitle),
                    ],
                  ),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayTitle.isNotEmpty) ...[
                        Text(displayTitle, style: _boldStyle),
                        const SizedBox(height: 10),
                      ],
                      Text(displaySubtitle, style: _detailSubtitleStyle),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${'Ad'.tr}: $adPercent%', style: _boldStyle),
                          const SizedBox(width: 20),
                          Text('${'Spam'.tr}: $spamPercent%',
                              style: _boldStyle),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _ellipsis(String text, {TextStyle? style}) => Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      );
}

class DismissibleNotificationTile extends StatefulWidget {
  const DismissibleNotificationTile({
    super.key,
    required this.record,
    required this.onDelete,
    required this.child,
  });

  final Record record;
  final Future<void> Function(Record record) onDelete;
  final Widget child;

  @override
  State<DismissibleNotificationTile> createState() =>
      _DismissibleNotificationTileState();
}

class _DismissibleNotificationTileState
    extends State<DismissibleNotificationTile>
    with SingleTickerProviderStateMixin {
  static const _deleteColor = Color(0xFFE53935);
  static const _itemSpacing = 8.0;
  static const _dismissThreshold = 0.32;
  static const _maxDragFraction = 0.52;

  AnimationController? _snapController;
  Animation<double>? _snapAnimation;
  double _dragOffset = 0;
  bool _thresholdReached = false;
  bool _dismissing = false;
  bool _deleteRequested = false;

  void _onSnapTick() {
    if (!mounted || _snapAnimation == null) {
      return;
    }
    setState(() => _dragOffset = _snapAnimation!.value);
  }

  void _onSnapStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !_dismissing ||
        !mounted ||
        _deleteRequested) {
      return;
    }
    _deleteRequested = true;
    unawaited(_runDelete());
  }

  Future<void> _runDelete() async {
    try {
      await widget.onDelete(widget.record);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _deleteRequested = false;
      _dismissing = false;
      setState(() => _dragOffset = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    controller
      ..addListener(_onSnapTick)
      ..addStatusListener(_onSnapStatus);
    _snapController = controller;
  }

  @override
  void dispose() {
    final controller = _snapController;
    if (controller != null) {
      controller
        ..removeListener(_onSnapTick)
        ..removeStatusListener(_onSnapStatus)
        ..dispose();
      _snapController = null;
    }
    super.dispose();
  }

  void _snapTo(double target, {required bool dismiss}) {
    final controller = _snapController;
    if (controller == null || !mounted) {
      return;
    }
    _dismissing = dismiss;
    if (!dismiss) {
      _thresholdReached = false;
    }
    _snapAnimation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    controller
      ..duration = Duration(milliseconds: dismiss ? 180 : 220)
      ..reset()
      ..forward();
  }

  void _onHorizontalDragUpdate(double deltaDx, double maxDrag) {
    final controller = _snapController;
    if (!mounted ||
        controller == null ||
        controller.isAnimating ||
        _deleteRequested) {
      return;
    }
    final next = (_dragOffset - deltaDx).clamp(0.0, maxDrag);
    final reached = next >= maxDrag * _dismissThreshold;
    if (reached && !_thresholdReached) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _dragOffset = next;
      _thresholdReached = reached;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (!mounted || _snapController == null || _deleteRequested) {
      return;
    }
    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldDismiss = _dragOffset >= maxDrag * _dismissThreshold ||
        velocity < -900;
    if (shouldDismiss) {
      _snapTo(maxDrag, dismiss: true);
      return;
    }
    _thresholdReached = false;
    _snapTo(0, dismiss: false);
  }

  static const _deleteTrailingPadding = 22.0;
  static const _minStripWidthForDeleteText = 88.0;

  Widget _deleteLabel(double reveal, double stripWidth) {
    final showText = stripWidth >= _minStripWidthForDeleteText;

    return Opacity(
      opacity: (reveal * 1.15).clamp(0.0, 1.0),
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                UniconsLine.trash_alt,
                color: Colors.white,
                size: 20,
              ),
              if (showText) ...[
                const SizedBox(width: 8),
                Text(
                  'Delete'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: _itemSpacing),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxDrag = constraints.maxWidth * _maxDragFraction;
          final offset = _dragOffset.clamp(0.0, maxDrag);
          final reveal = maxDrag > 0
              ? Curves.easeOutCubic.transform(offset / maxDrag).toDouble()
              : 0.0;
          return Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              if (offset > 0.5)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: offset,
                  child: ClipRRect(
                    borderRadius: kTileBorderRadiusAll,
                    clipBehavior: Clip.antiAlias,
                    child: ColoredBox(
                      color: _deleteColor,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding:
                              EdgeInsets.only(right: _deleteTrailingPadding),
                          child: _deleteLabel(reveal, offset),
                        ),
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) =>
                    _onHorizontalDragUpdate(details.delta.dx, maxDrag),
                onHorizontalDragEnd: (details) =>
                    _onHorizontalDragEnd(details, maxDrag),
                child: Transform.translate(
                  offset: Offset(-offset, 0),
                  child: widget.child,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
