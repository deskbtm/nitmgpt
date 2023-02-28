import 'dart:developer';
import 'package:get/get.dart';
import 'package:nitmgpt/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:device_apps/device_apps.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';

import '../hive_fields_mgmt.dart';
import '../models/record.dart';

getFieldsMeans(Box box) {
  return ruleFieldsMap.values
      .map((element) {
        var mean = box.get(element.name, defaultValue: element.means);
        return "the field `${element.name}`: $mean";
      })
      .toList()
      .join(',');
}

Future<GPTResponse?> inquireChatgpt(String question, Box settingsBox) async {
  String openaiApiKey = settingsBox.get(HiveFieldsMgmt.openaiApiKey);
  String proxyUrl = settingsBox.get(HiveFieldsMgmt.proxyUrl);
  final openAI = OpenAI.instance.build(
    token: openaiApiKey,
    baseOption: HttpSetup(
      receiveTimeout: 100000,
      proxyUrl: proxyUrl != '' ? proxyUrl : null,
    ),
    isLogger: kDebugMode,
  );

  final request = CompleteText(
    prompt: question,
    model: kTranslateModelV3,
    maxTokens: 200,
    stream: false,
  );

  var result = await openAI.onCompleteText(request: request);
  var choicesTexts = result?.choices
          .map((e) => e.text.replaceAll(RegExp(r'[\n\r]'), ''))
          .toSet()
          .toList() ??
      [];
  String anwser = choicesTexts.join(' ');
  Map<String, dynamic>? json = looseJSONParse(anwser);
  if (json != null) {
    return GPTResponse.fromJson(json);
  }

  return null;
}

saveRecords() {}

handleNotificationListener(
    NotificationEvent event, List<Application> deviceApps) async {
  Box<String> ignoredAppsBox = await Hive.openBox(IGNORED_APPS);
  if (ignoredAppsBox.values.contains(event.packageName)) {
    return;
  }

  Box settingsBox = await Hive.openBox(SETTINGS);
  String fieldsMeans = getFieldsMeans(settingsBox);
  String question =
      'Determine "${event.title} ${event.text}", $fieldsMeans, return json';
  log(question);

  var answer = await inquireChatgpt(question, settingsBox);

  if (answer != null) {
    Application? app = deviceApps.firstWhereOrNull(
        (element) => element.packageName == event.packageName);
    // NotificationsListener.cancelNotification(event.key ?? '');

    Record record = Record()
      ..isAd = answer.isAd ?? false
      ..adProbability = answer.adProbability ?? .0
      ..isSpam = answer.isSpam ?? false
      ..spamProbability = answer.spamProbability ?? .0
      ..appName = app != null ? app.appName : ''
      ..packageName = event.packageName ?? ''
      ..notificationText = event.text ?? ''
      ..notificationTitle = event.title ?? ''
      ..timestamp = event.timestamp ?? 0
      ..createTime = event.createAt!
      ..uid = event.uniqueId ?? '';
  }
}

permanentListenerServiceMain() async {
  await Hive.initFlutter();
  Hive.registerAdapter(RecordAdapter());
  await NotificationsListener.initialize();
  var deviceApps = await DeviceApps.getInstalledApplications();

  NotificationsListener.receivePort
      ?.listen((message) => handleNotificationListener(message, deviceApps));
}
