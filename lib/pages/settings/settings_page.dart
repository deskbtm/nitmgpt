import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:nitmgpt/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final watcher = AppScope.of(context).watcher;

    final sectionHeaderStyle = TextStyle(fontSize: 14, color: primaryColor);

    return GlassTabShell(
      appBar: GlassAppBar(
        centerTitle: false,
        title: Text(
          'Settings'.tr,
          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          OpaqueGroupedSection(
            header: 'app'.tr,
            headerStyle: sectionHeaderStyle,
            children: [
              SignalBuilder(
                builder: (context) {
                  if (settings.ownedApp.value) {
                    return const SizedBox.shrink();
                  }
                  return OpaqueListTile(
                    title: Text('Get this App'.tr),
                    showChevron: true,
                    onTap: () => settings.verifyOwnedApp(context),
                  );
                },
              ),
              OpaqueListTile(
                title: Text('Custom Rules'.tr),
                showChevron: true,
                onTap: () => context.push(AppRoutes.rules),
              ),
              OpaqueListTile(
                title: Text('Model configuration'.tr),
                showChevron: true,
                onTap: () => context.push(AppRoutes.gemmaModels),
              ),
              OpaqueListTile(
                title: Text('Bug report'.tr),
                showChevron: true,
                onTap: () async => open('$githubRepoUrl/issues'),
              ),
            ],
          ),
          OpaqueGroupedSection(
            header: 'system'.tr,
            headerStyle: sectionHeaderStyle,
            children: [
              OpaqueListTile(
                title: const Text('Language'),
                trailing: Text('_locale'.tr),
                onTap: settings.setLanguage,
              ),
              OpaqueListTile(
                title: Text('Proxy'.tr),
                trailing: SignalBuilder(
                  builder: (context) => Text(settings.proxyUri.value),
                ),
                onTap: () => settings.setupProxy(context),
              ),
              OpaqueListTile(
                title: Text('Clear records'.tr),
                onTap: watcher.clearRecords,
              ),
              OpaqueListTile(
                title: Text('Update'.tr),
                trailing: _UpdateTrailing(settings: settings),
                onTap: () => settings.checkUpdate(context),
              ),
            ],
          ),
          OpaqueGroupedSection(
            header: 'permission'.tr,
            headerStyle: sectionHeaderStyle,
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
                  await DisableBatteryOptimization.showEnableAutoStartSettings(
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
                title: Text('Manufacturer specific Battery Optimization'.tr),
                showChevron: true,
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableManufacturerBatteryOptimizationSettings(
                    'Your device has additional battery optimization',
                    'Follow the steps and disable the optimizations to allow smooth functioning of this app',
                  );
                },
              ),
              OpaqueListTile(
                title: Text(
                  'Exit App'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(
                  'This will exit all services'.tr,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                onTap: watcher.exitAllServices,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateTrailing extends StatelessWidget {
  const _UpdateTrailing({required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final version = settings.currentVersion.value;
        return Text(version != null ? 'v$version' : '');
      },
    );
  }
}
