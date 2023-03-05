import 'dart:developer';
import 'dart:ui';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:get/get.dart';
import 'package:device_apps/device_apps.dart';
import 'package:nitmgpt/firebase.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:nitmgpt/utils.dart';
import 'package:realm/realm.dart';

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

Future<GPTResponse?> _inquireGPT(String question, Settings? settings) async {
  final openAI = OpenAI.instance.build(
    token: settings?.openAiKey,
    baseOption: HttpSetup(
      receiveTimeout: 100000,
      proxyUrl: settings != null && settings.proxyUri != ''
          ? settings.proxyUri
          : null,
    ),
    isLogger: true,
  );

  final request = CompleteText(
    prompt: question,
    model: kTranslateModelV3,
    maxTokens: 200,
    stream: false,
  );

  var result = await openAI.onCompleteText(request: request).catchError((err) {
    log('$err');
  });
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

bool _determineRemove(GPTResponse answer, Settings? settings) {
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

late List<Application> _deviceApps;
late ServiceInstance _backgroundService;

@pragma('vm:entry-point')
handleNotificationListener(NotificationEvent event) async {
  try {
    Settings settings = getSettingInstance();

    if (settings.openAiKey == null || settings.openAiKey == '') {
      if (_isUnsetApiKey) {
        _isUnsetApiKey = false;
        _backgroundService.invoke("set_api_key");
      }
      return;
    }

    if (settings.ignoredApps.contains(event.packageName)) {
      return;
    }

    String fieldsMeans = _getFieldsMeans(settings);
    String question =
        'Determine "${event.title} ${event.text}", $fieldsMeans, only return json.';
    log(question, name: 'permanent_listener_service');

    var answer = await _inquireGPT(question, settings);

    if (answer != null) {
      Application? app = _deviceApps.firstWhereOrNull(
          (element) => element.packageName == event.packageName);
      bool isRemove = _determineRemove(answer, settings);

      log("Notification removed: $isRemove");

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
        await realm.writeAsync(() {
          realm.add(record);
        });
        _backgroundService.invoke('update_records');
      }
    }
  } catch (e, stackTrace) {
    log(e.toString(), name: 'permanent_listener_service');
    FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
  }
}

@pragma('vm:entry-point')
permanentListenerServiceMain(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  _backgroundService = service;

  await initFirebase();

  _deviceApps = await DeviceApps.getInstalledApplications();

  await NotificationsListener.initialize(
    callbackHandle: handleNotificationListener,
  );
}
