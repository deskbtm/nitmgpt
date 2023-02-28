import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:nitmgpt/hive_fields_mgmt.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';

class RulesController extends GetxController {
  static RulesController get to => Get.find();

  final formKey = GlobalKey<FormState>();
  final selectedApp = <ApplicationWithIcon>[].obs;
  late Box ignoredAppsBox;
  late Box settingsBox;

  final _watcherController = WatcherController.to;

  @override
  void onInit() async {
    super.onInit();

    ignoredAppsBox = await Hive.openBox(IGNORED_APPS);
    settingsBox = await Hive.openBox(SETTINGS);

    setupIgnoredApps();
    setupQuestionFields();
  }

  @override
  void onClose() {
    for (var e in ruleFieldsMap.values) {
      if (e.textEditingController.text == '') {
        e.textEditingController.dispose();
      }
    }
    super.onClose();
  }

  addSelectedApp(ApplicationWithIcon app) {
    if (!selectedApp.contains(app)) {
      ignoredAppsBox.add(app.packageName);
      selectedApp.add(app);
    }
  }

  removeSelectedApp(ApplicationWithIcon app) {
    int index = ignoredAppsBox.values
        .toList()
        .indexWhere((element) => element == app.packageName);
    ignoredAppsBox.deleteAt(index);
    selectedApp.remove(app);
  }

  String? validator(String? value) {
    if (value != null && value.isEmpty) {
      return 'Please this field must be filled';
    }
    return null;
  }

  setupQuestionFields() {
    for (var e in ruleFieldsMap.values) {
      e.textEditingController.text =
          settingsBox.get(e.name, defaultValue: e.means);
    }
  }

  setupIgnoredApps() {
    for (var packageName in ignoredAppsBox.values) {
      var r = _watcherController.deviceApps
          .firstWhereOrNull((ele) => ele.packageName == packageName);
      if (r != null) {
        selectedApp.add(r);
      }
    }
  }

  submit() async {
    for (var e in ruleFieldsMap.values) {
      await settingsBox.put(e.name, e.textEditingController.text);
    }
  }
}
