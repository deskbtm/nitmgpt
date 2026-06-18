import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/frosted_glass_surface.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';

class NotificationTitle extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? appName;
  final String? tileKey;
  final String? dateTime;
  final double? adProbability;
  final double? spamProbability;
  final Uint8List? icon;

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

  @override
  Widget build(BuildContext context) {
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
                    Flexible(
                      child: Text(
                        title ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        appName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              subtitle: RichText(
                maxLines: 2,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: dateTime ?? '',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 0, 53, 2),
                      ),
                    ),
                    const TextSpan(text: ' : '),
                    TextSpan(
                      text: subtitle ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      Text(
                        subtitle ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${'Ad'.tr}: ${adProbability! * 100}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            '${'Spam'.tr}: ${spamProbability! * 100}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
}
