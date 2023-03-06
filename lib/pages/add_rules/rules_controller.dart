import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';
import 'package:nitmgpt/utils.dart';

class RulesController extends GetxController {
  static RulesController get to => Get.find();

  late final Settings settings;

  final formKey = GlobalKey<FormState>();

  final selectedApp = <ApplicationWithIcon>[].obs;

  final adProbabilityController = TextEditingController();

  final spamProbabilityController = TextEditingController();

  final limitController = TextEditingController();

  final _watcherController = WatcherController.to;

  @override
  void onInit() async {
    super.onInit();
    settings = getSettingInstance();

    setupIgnoredApps();
    setupQuestionFields();

    if (settings.presetAdProbability != null) {
      adProbabilityController.text = settings.presetAdProbability.toString();
    }

    if (settings.presetSpamProbability != null) {
      spamProbabilityController.text =
          settings.presetSpamProbability.toString();
    }

    limitController.text = settings.presetLimit.toString();
  }

  @override
  void onClose() {
    for (var e in ruleFieldsMap.values) {
      if (e.textEditingController.text == '') {
        e.textEditingController.dispose();
      }
    }
    spamProbabilityController.dispose();
    adProbabilityController.dispose();
    limitController.dispose();
    super.onClose();
  }

  String? validator(String? value) {
    if (value != null && value.isEmpty) {
      return 'Please this field must be filled';
    }
    return null;
  }

  String? validatorPercent(String? value) {
    if (value != null && value.isEmpty) {
      return 'Please this field must be filled';
    }
    return null;
  }

  addSelectedApp(ApplicationWithIcon app) {
    if (!selectedApp.contains(app)) {
      realm.write(() {
        settings.ignoredApps.add(app.packageName);
      });
      selectedApp.add(app);
    }
  }

  removeSelectedApp(ApplicationWithIcon app) {
    realm.write(() {
      settings.ignoredApps.removeWhere((element) => element == app.packageName);
    });
    selectedApp.remove(app);
  }

  setupQuestionFields() {
    for (var e in ruleFieldsMap.values) {
      if (settings.ruleFields != null) {
        e.textEditingController.text = settings.ruleFields!.toMap()[e.name];
      } else {
        e.textEditingController.text = e.means;
      }
    }
  }

  setupIgnoredApps() {
    for (var packageName in settings.ignoredApps) {
      var r = _watcherController.deviceApps
          .firstWhereOrNull((ele) => ele.packageName == packageName);
      if (r != null) {
        selectedApp.add(r);
      }
    }
  }

  submit() async {
    realm.write(() {
      settings.ruleFields = RuleFields(
        ruleFieldsMap['is_ad']!.textEditingController.text,
        ruleFieldsMap['ad_probability']!.textEditingController.text,
        ruleFieldsMap['is_spam']!.textEditingController.text,
        ruleFieldsMap['spam_probability']!.textEditingController.text,
        ruleFieldsMap['sentence']!.textEditingController.text,
      );
    });

    realm.write(() {
      settings.presetAdProbability = adProbabilityController.text.isEmpty
          ? null
          : double.tryParse(adProbabilityController.text);

      settings.presetSpamProbability = spamProbabilityController.text.isEmpty
          ? null
          : double.tryParse(spamProbabilityController.text);

      int? limitVal = int.tryParse(limitController.text);
      if (limitController.text.isNotEmpty && limitVal != null) {
        settings.presetLimit = limitVal;
      }
    });
  }
}
