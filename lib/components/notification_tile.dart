import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationTitle extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String? appName;
  final String? tileKey;
  final String? dateTime;
  final Uint8List? icon;

  const NotificationTitle({
    super.key,
    this.title,
    this.icon,
    this.subtitle,
    this.tileKey,
    this.appName,
    this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 7),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 23,
                  height: 23,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: CachedMemoryImage(
                      width: 17,
                      height: 17,
                      bytes: icon,
                      uniqueKey: tileKey ?? '',
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
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              children: [
                TextSpan(
                  text: dateTime ?? '',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 53, 2),
                  ),
                ),
                const TextSpan(text: ' : '),
                TextSpan(
                    text: subtitle ?? '', style: const TextStyle(fontSize: 12))
              ],
            ),
          ),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title != null && title!.isNotEmpty
                      ? Column(
                          children: [
                            Text(
                              title ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        )
                      : Container(),
                  Text(
                    subtitle ?? '',
                    style: const TextStyle(fontSize: 12),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
