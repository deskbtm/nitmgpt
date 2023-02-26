import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/pages/add_rules/add_rules_controller.dart';
import 'package:nitmgpt/pages/settings/settings_controller.dart';
import 'package:unicons/unicons.dart';

import '../home/watcher_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  SettingsPage({super.key});

  final RulesController _rulesController = RulesController.to;
  final watcher = WatcherController.to;

  @override
  Widget build(BuildContext context) {
    ListTile updateTile = ListTile(
      onTap: controller.checkUpdate,
      title: Text("Update".tr),
      trailing: controller.hasNewVersion()
          ? Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                      top: 2, bottom: 2, left: 5, right: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber[300],
                    borderRadius: const BorderRadius.all(Radius.circular(1000)),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text('v${controller.latestVersion.string}')
              ],
            )
          : Text('v${controller.currentVersion.string}'),
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
          Obx(
            () => Column(
              children: [
                _rulesController.rules.isEmpty
                    ? Container()
                    : const SizedBox(
                        height: 40,
                        child: ListTile(
                          title: Text(
                            "listening apps",
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ),
                      ),
                ..._rulesController.rules
                    .map(
                      (element) => ListTile(
                        onTap: () {
                          Get.toNamed('/add_rules', parameters: {
                            "action": "update",
                            "packageName": element.packageName
                          });
                        },
                        trailing: InkWell(
                          onTap: () {
                            _rulesController.deleteRule(element);
                          },
                          child: Icon(
                            UniconsLine.times,
                            color: Colors.green[900],
                          ),
                        ),
                        leading: SizedBox(
                          width: 45,
                          height: 45,
                          child: CachedMemoryImage(
                            bytes: element.icon,
                            width: 45,
                            height: 45,
                            uniqueKey: element.packageName,
                          ),
                        ),
                        title: Text(element.appName),
                        subtitle: Text(element.packageName),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 40,
                child: ListTile(
                  title: Text(
                    "system".tr,
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ),
              ),
              ListTile(
                onTap: controller.setLanguage,
                title: const Text("Language"),
                trailing: Text('_locale'.tr),
              ),
              ListTile(
                onTap: watcher.clearRecords,
                title: Text("Clear records".tr),
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
                    "permission".tr,
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ),
              ),
              ListTile(
                onTap: () {
                  NotificationsListener.openPermissionSettings();
                },
                title: Text("Notification listener permission".tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization.showEnableAutoStartSettings(
                      "Enable Auto Start",
                      "Follow the steps and enable the auto start of this app");
                },
                title: Text("Auto start".tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableBatteryOptimizationSettings();
                },
                title: Text("Battery optimization".tr),
              ),
              ListTile(
                onTap: () async {
                  await DisableBatteryOptimization
                      .showDisableManufacturerBatteryOptimizationSettings(
                          "Your device has additional battery optimization",
                          "Follow the steps and disable the optimizations to allow smooth functioning of this app");
                },
                title: Text("Manufacturer specific Battery Optimization".tr),
              ),
            ],
          )
        ],
      ),
    );
  }
}
