import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:nitmgpt/utils.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final watcher = AppScope.of(context).watcher;

    final sectionHeaderStyle = TextStyle(fontSize: 14, color: primaryColor);

    return SignalBuilder(
      builder: (context) {
        appLocale.value;
        return TabPageShell(
          body: ListView(
            padding: EdgeInsets.fromLTRB(
              21,
              TabPageShell.scrollTopPadding(context),
              21,
              32,
            ),
            children: [
              SecondaryPageScaffold.largeTitle('Settings'.tr),
              const SizedBox(height: 20),
              SignalBuilder(
                builder: (context) {
                  final listening = watcher.isListening.value;
                  return OpaqueGroupedSection(
                    header: 'app'.tr,
                    headerStyle: sectionHeaderStyle,
                    children: [
                      OpaqueListTile(
                        leading: Icon(
                          listening
                              ? UniconsLine.record_audio
                              : UniconsLine.play,
                          size: 18,
                        ),
                        title: Text(
                          listening
                              ? '${'Listening'.tr}...'
                              : 'Start listening'.tr,
                        ),
                        horizontalTitleGap: 8,
                        minLeadingWidth: 22,
                        onTap: watcher.startNotificationService,
                      ),
                      if (!settings.ownedApp.value)
                        OpaqueListTile(
                          title: Text('Get this App'.tr),
                          showChevron: true,
                          onTap: () => settings.verifyOwnedApp(context),
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
                  );
                },
              ),
              OpaqueGroupedSection(
                header: 'system'.tr,
                headerStyle: sectionHeaderStyle,
                children: [
                  OpaqueListTile(
                    title: Text('Language'.tr),
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
                    title: Text('Export History'.tr),
                    onTap: watcher.exportXlsx,
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
                  OpaqueListTile(
                    title: Text('permission'.tr),
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.permissions),
                  ),
                ],
              ),
              OpaqueGroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  OpaqueListTile(
                    title: Text(
                      'Exit App'.tr,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () => _confirmExitApp(context, watcher),
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

Future<void> _confirmExitApp(BuildContext context, WatcherStore watcher) {
  return showAppAlertDialog(
    context: context,
    title: 'Exit App'.tr,
    message: 'This will exit all services'.tr,
    confirmText: 'Exit App'.tr,
    cancelText: 'Cancel'.tr,
    onCancel: (dialogContext) async {
      popDialog(dialogContext);
    },
    onConfirm: (dialogContext) async {
      popDialog(dialogContext);
      await watcher.exitAllServices();
    },
  );
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
