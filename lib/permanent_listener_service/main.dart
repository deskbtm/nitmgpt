import 'dart:developer';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:device_apps/device_apps.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:realm/realm.dart';
import '../models/record.dart';
import '../utils.dart';

_getFieldsMeans(Settings? settings) {
  return ruleFieldsMap.values
      .map((element) {
        var mean = settings?.ruleFields != null
            ? settings!.ruleFields!.toMap()[element.name]
            : element.means;
        return "the field `${element.field}`: $mean";
      })
      .toList()
      .join(',');
}

Future<GPTResponse?> inquireChatgpt(String question, Settings? settings) async {
  final openAI = OpenAI.instance.build(
    token: settings?.openaiApiKey,
    baseOption: HttpSetup(
      receiveTimeout: 100000,
      proxyUrl: settings != null && settings.proxyUri != ''
          ? settings.proxyUri
          : null,
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
  String answer = choicesTexts.join(' ');
  Map<String, dynamic>? json = looseJSONParse(answer);
  if (json != null) {
    return GPTResponse.fromJson(json);
  }

  return null;
}

bool determineRemove(GPTResponse answer, Settings? settings) {
  bool adRemoved = false, spamRemoved = false;
  double? adProbability = settings?.presetAdProbability;
  double? spamProbability = settings?.presetSpamProbability;

  if (answer.isAd != null && answer.isAd!) {
    if (adProbability != null &&
        answer.adProbability != null &&
        answer.adProbability! > adProbability) {
      adRemoved = false;
    }

    adRemoved = true;
  }

  if (answer.isSpam != null && answer.isSpam!) {
    if (spamProbability != null &&
        answer.spamProbability != null &&
        answer.spamProbability! > spamProbability) {
      spamRemoved = false;
    }

    spamRemoved = true;
  }

  bool isRemove = adRemoved || spamRemoved;
  return isRemove;
}

bool _isUnsetApiKey = true;

handleNotificationListener(NotificationEvent event, ServiceInstance service,
    List<Application> deviceApps) async {
  Settings settings = getSettingInstance();

  if (settings.openaiApiKey == null) {
    if (_isUnsetApiKey) {
      _isUnsetApiKey = false;
      service.invoke("set_api_key");
    }
    return;
  }

  if (settings.ignoredApps.contains(event.packageName)) {
    return;
  }

  String fieldsMeans = _getFieldsMeans(settings);
  String question =
      'Determine "${event.title} ${event.text}", $fieldsMeans, return json';
  log(question);

  var answer = await inquireChatgpt(question, settings);

  if (answer != null) {
    Application? app = deviceApps.firstWhereOrNull(
        (element) => element.packageName == event.packageName);

    bool isRemove = determineRemove(answer, settings);

    if (isRemove) {
      NotificationsListener.cancelNotification(event.key ?? '');
      Record record = Record(
        ObjectId(),
        isAd: answer.isAd,
        adProbability: answer.adProbability,
        isSpam: answer.isSpam,
        spamProbability: answer.spamProbability,
        appName: app?.appName,
        packageName: event.packageName,
        notificationKey: event.key,
        notificationText: event.text,
        notificationTitle: event.title,
        timestamp: event.timestamp,
        createTime: event.createAt,
        uid: event.uniqueId,
      );
      realm.write(() {
        realm.add(record);
      });
      service.invoke('update_records');
    }
  }
}

permanentListenerServiceMain(ServiceInstance service) async {
  await NotificationsListener.initialize();
  var deviceApps = await DeviceApps.getInstalledApplications();

  NotificationsListener.receivePort?.listen(
      (message) => handleNotificationListener(message, service, deviceApps));
}
