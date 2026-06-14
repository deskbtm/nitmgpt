import 'package:flutter/material.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/app/app_scope.dart';
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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          GlassGroupedSection(
            quality: contentGlassQuality,
            header: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('app'.tr, style: sectionHeaderStyle),
            ),
            children: [
              SignalBuilder(
                builder: (context) {
                  if (settings.ownedApp.value) {
                    return const SizedBox.shrink();
                  }
                  return GlassListTile(
                    title: Text('Get this App'.tr),
                    trailing: GlassListTile.chevron,
                    onTap: () => settings.verifyOwnedApp(context),
                  );
                },
              ),
              GlassListTile(
                title: Text('Custom Rules'.tr),
                trailing: GlassListTile.chevron,
                onTap: () => context.push(AppRoutes.rules),
              ),
              GlassListTile(
                title: Text('Bug report'.tr),
                trailing: GlassListTile.chevron,
                onTap: () async => open('$githubRepoUrl/issues'),
              ),
            ],
          ),
          GlassGroupedSection(
            quality: contentGlassQuality,
            header: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('system'.tr, style: sectionHeaderStyle),
            ),
            children: [
              GlassListTile(
                title: const Text('Language'),
                trailing: Text('_locale'.tr),
                onTap: settings.setLanguage,
              ),
              GlassListTile(
                title: Text('Proxy'.tr),
                trailing: SignalBuilder(
                  builder: (context) => Text(settings.proxyUri.value),
                ),
                onTap: () => settings.setupProxy(context),
              ),
              GlassListTile(
                title: Text('Clear records'.tr),
                onTap: watcher.clearRecords,
              ),
              GlassListTile(
                title: Text('Update'.tr),
                trailing: _UpdateTrailing(settings: settings),
                onTap: () => settings.checkUpdate(context),
              ),
            ],
          ),
          GlassGroupedSection(
            quality: contentGlassQuality,
            header: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text('permission'.tr, style: sectionHeaderStyle),
            ),
            children: [
              GlassListTile(
                title: Text('Notification listener permission'.tr),
                trailing: GlassListTile.chevron,
                onTap: NotificationsListener.openPermissionSettings,
              ),
              GlassListTile(
                title: Text('Auto start'.tr),
                trailing: GlassListTile.chevron,
                onTap: () async {
                  await DisableBatteryOptimization.showEnableAutoStartSettings(
                    'Enable Auto Start',
                    'Follow the steps and enable the auto start of this app',
                  );
                },
              ),
              GlassListTile(
                title: Text('Battery optimization'.tr),
                trailing: GlassListTile.chevron,
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableBatteryOptimizationSettings();
                },
              ),
              GlassListTile(
                title: Text('Manufacturer specific Battery Optimization'.tr),
                trailing: GlassListTile.chevron,
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableManufacturerBatteryOptimizationSettings(
                    'Your device has additional battery optimization',
                    'Follow the steps and disable the optimizations to allow smooth functioning of this app',
                  );
                },
              ),
              GlassListTile(
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
