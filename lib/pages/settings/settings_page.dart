import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/theme.dart';
import 'package:nitmgpt/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final watcher = AppScope.of(context).watcher;

    final updateTile = ListTile(
      onTap: () => settings.checkUpdate(context),
      title: Text('Update'.tr),
      trailing: SignalBuilder(
        builder: (context) {
          return settings.hasNewVersion()
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                        top: 2,
                        bottom: 2,
                        left: 5,
                        right: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[300],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(1000),
                        ),
                      ),
                      child: const Text(
                        'New',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('v${settings.latestVersion.value}'),
                  ],
                )
              : Text('v${settings.currentVersion.value}');
        },
      ),
    );

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 50),
        children: [
          ListTile(
            title: Text(
              'Settings'.tr,
              style: const TextStyle(fontSize: 34),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              SizedBox(
                height: 40,
                child: ListTile(
                  title: Text(
                    'app'.tr,
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ),
              ),
              SignalBuilder(
                builder: (context) {
                  return settings.ownedApp.value
                      ? const SizedBox.shrink()
                      : ListTile(
                          onTap: () => settings.verifyOwnedApp(context),
                          title: Text('Get this App'.tr),
                        );
                },
              ),
              ListTile(
                onTap: () => settings.setupOpenAiKey(context),
                title: const Text('OpenAI API Key'),
                trailing: SignalBuilder(
                  builder: (context) => Text(
                    settings.openAiKey.value.isEmpty ? '' : '******',
                  ),
                ),
              ),
              ListTile(
                onTap: () => context.push(AppRoutes.rules),
                title: Text('Custom Rules'.tr),
              ),
              ListTile(
                onTap: () async => open('$githubRepoUrl/issues'),
                title: Text('Bug report'.tr),
              ),
            ],
          ),
          Column(
            children: [
              SizedBox(
                height: 40,
                child: ListTile(
                  title: Text(
                    'system'.tr,
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ),
              ),
              ListTile(
                onTap: settings.setLanguage,
                title: const Text('Language'),
                trailing: Text('_locale'.tr),
              ),
              ListTile(
                onTap: () => settings.setupProxy(context),
                title: Text('Proxy'.tr),
                trailing: SignalBuilder(
                  builder: (context) => Text(settings.proxyUri.value),
                ),
              ),
              ListTile(
                onTap: watcher.clearRecords,
                title: Text('Clear records'.tr),
              ),
              updateTile,
            ],
          ),
          Column(
            children: [
              SizedBox(
                height: 40,
                child: ListTile(
                  title: Text(
                    'permission'.tr,
                    style: TextStyle(fontSize: 14, color: primaryColor),
                  ),
                ),
              ),
              ListTile(
                onTap: NotificationsListener.openPermissionSettings,
                title: Text('Notification listener permission'.tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization.showEnableAutoStartSettings(
                    'Enable Auto Start',
                    'Follow the steps and enable the auto start of this app',
                  );
                },
                title: Text('Auto start'.tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableBatteryOptimizationSettings();
                },
                title: Text('Battery optimization'.tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableManufacturerBatteryOptimizationSettings(
                    'Your device has additional battery optimization',
                    'Follow the steps and disable the optimizations to allow smooth functioning of this app',
                  );
                },
                title: Text('Manufacturer specific Battery Optimization'.tr),
              ),
              ListTile(
                onTap: watcher.exitAllServices,
                title: Text(
                  'Exit App'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  'This will exit all services'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
