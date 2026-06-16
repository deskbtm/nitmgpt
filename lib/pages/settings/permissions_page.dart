import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:signals_flutter/signals_flutter.dart';

class PermissionsPage extends StatelessWidget {
  const PermissionsPage({super.key});

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
              SecondaryPageScaffold.largeTitle('permission'.tr),
              const SizedBox(height: 20),
              OpaqueGroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  OpaqueListTile(
                    title: Text('Notification listener permission'.tr),
                    showChevron: true,
                    onTap: NotificationsListener.openPermissionSettings,
                  ),
                  OpaqueListTile(
                    title: Text('Auto start'.tr),
                    showChevron: true,
                    onTap: () async {
                      await DisableBatteryOptimization
                          .showEnableAutoStartSettings(
                        'Enable Auto Start',
                        'Follow the steps and enable the auto start of this app',
                      );
                    },
                  ),
                  OpaqueListTile(
                    title: Text('Battery optimization'.tr),
                    showChevron: true,
                    onTap: () async {
                      await DisableBatteryOptimization
                          .showDisableBatteryOptimizationSettings();
                    },
                  ),
                  OpaqueListTile(
                    title: Text(
                      'Manufacturer specific Battery Optimization'.tr,
                    ),
                    showChevron: true,
                    onTap: () async {
                      await DisableBatteryOptimization
                          .showDisableManufacturerBatteryOptimizationSettings(
                        'Your device has additional battery optimization',
                        'Follow the steps and disable the optimizations to allow smooth functioning of this app',
                      );
                    },
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
