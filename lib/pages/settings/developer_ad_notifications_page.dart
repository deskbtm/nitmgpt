import 'package:flutter/material.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/dev/developer_ad_notification_samples.dart';
import 'package:nitmgpt/dev/developer_ad_notification_sender.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class DeveloperAdNotificationsPage extends StatelessWidget {
  const DeveloperAdNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        appLocale.value;
        final topInset = SecondaryPageScaffold.scrollTopPadding(context);

        return SecondaryPageScaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(21, topInset, 21, 32),
            children: [
              SecondaryPageScaffold.largeTitle('Ad notifications'.tr),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Sends a system notification and injects into the filter.'.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              OpaqueGroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  for (final sample in developerAdNotificationSamples)
                    OpaqueListTile(
                      title: Text(sample.labelKey.tr),
                      subtitle: Text(
                        sample.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(UniconsLine.plane_fly, size: 20),
                        color: primaryColor,
                        tooltip: 'Send'.tr,
                        onPressed: () => sendDeveloperAdNotification(sample),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
