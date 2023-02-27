import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';

class CustomField {
  final String field;
  final String name;
  final String means;
  final TextEditingController textEditingController;
  double? width;

  CustomField({
    required this.field,
    required this.name,
    required this.means,
    required this.textEditingController,
    this.width = 200,
  });
}

class RuleFormController extends GetxController {
  static RuleFormController get to => Get.find();

  final formKey = GlobalKey<FormState>();
  final selectedApp = <ApplicationWithIcon>[].obs;
  late Box ignoredAppsBox;
  late Box questionFieldsBox;

  final _watcherController = WatcherController.to;

  final fieldsMap = {
    'is_ad': CustomField(
      field: '`is_ad` ',
      name: 'is_ad',
      means: ' means whether it is an advertisement ',
      textEditingController: TextEditingController(),
    ),
    'ad_probability': CustomField(
      field: '`ad_probability` ',
      name: 'ad_probability',
      means:
          ' means the probability that this sentence is classified as an advertisement ',
      textEditingController: TextEditingController(),
    ),
    'is_spam': CustomField(
      field: '`is_spam` ',
      name: 'is_spam',
      means: ' means whether it is spam ',
      textEditingController: TextEditingController(),
    ),
    'sentence': CustomField(
      field: '`sentence` ',
      name: 'sentence',
      means: ' means the input sentence ',
      textEditingController: TextEditingController(),
    ),
  };

  @override
  void onInit() async {
    super.onInit();

    ignoredAppsBox = await Hive.openBox('ignored_apps');
    questionFieldsBox = await Hive.openBox('question_fields');

    setupIgnoredApps();
    setupQuestionFields();
  }

  @override
  void onClose() {
    for (var e in fieldsMap.values) {
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

  String? validator(String? value) {
    if (value != null && value.isEmpty) {
      return 'Please this field must be filled';
    }
    return null;
  }

  setupQuestionFields() {
    for (var e in fieldsMap.values) {
      e.textEditingController.text =
          questionFieldsBox.get(e.name, defaultValue: e.means);
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
    for (var e in fieldsMap.values) {
      await questionFieldsBox.put(e.name, e.textEditingController.text);
    }
  }
}
