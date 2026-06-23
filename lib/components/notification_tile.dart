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
              tilePadding: const EdgeInsets.only(
                top: 10,
                left: 15,
                right: 15,
                bottom: 7,
              ),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
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
              ),
              subtitle: RichText(
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
    extends State<DismissibleNotificationTile> {
  static const _deleteColor = Color(0xFFE53935);
  static const _itemSpacing = 8.0;

  double _dragProgress = 0;

  void _onDismissUpdate(DismissUpdateDetails details) {
    if (details.reached && !details.previousReached) {
      HapticFeedback.lightImpact();
    }
    final nextProgress = details.progress.clamp(0.0, 1.0);
    if ((nextProgress - _dragProgress).abs() < 0.01) {
      return;
    }
    setState(() => _dragProgress = nextProgress);
  }

  @override
  Widget build(BuildContext context) {
    final reveal = Curves.easeOutCubic.transform(_dragProgress);

    return Padding(
      padding: const EdgeInsets.only(bottom: _itemSpacing),
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: kTileBorderRadiusAll,
              clipBehavior: Clip.antiAlias,
              child: ColoredBox(
                color: _deleteColor,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: Opacity(
                      opacity: (reveal * 1.15).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset((1 - reveal) * 14, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              UniconsLine.trash_alt,
                              color: Colors.white,
                              size: 20,
                            ),
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
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Dismissible(
            key: ValueKey(widget.record.id),
            direction: DismissDirection.endToStart,
            movementDuration: const Duration(milliseconds: 220),
            resizeDuration: const Duration(milliseconds: 260),
            dismissThresholds: const {
              DismissDirection.endToStart: 0.32,
            },
            background: const ColoredBox(color: Colors.transparent),
            onUpdate: _onDismissUpdate,
            onDismissed: (_) => widget.onDelete(widget.record),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
