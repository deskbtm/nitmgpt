import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/frosted_glass_surface.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';

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
  });

  final String? title;
  final String? subtitle;
  final String? appName;
  final String? tileKey;
  final String? dateTime;
  final double? adProbability;
  final double? spamProbability;
  final Uint8List? icon;

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

    return RepaintBoundary(
      child: FrostedGlassSurface(
        margin: const EdgeInsets.only(bottom: 8),
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
                          Text('${'Spam'.tr}: $spamPercent%', style: _boldStyle),
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
