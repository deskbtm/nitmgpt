import 'dart:developer';
import 'dart:ui';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/device_apps_compat.dart';
import 'package:nitmgpt/firebase.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:nitmgpt/utils.dart';
import 'package:realm/realm.dart';

class ForegroundTaskAction {
  static const promptApiKey = 'prompt_api_key';
  static const updateRecords = 'update_records';
}

const nitmForegroundServiceId = 888;

bool _isUnsetApiKey = true;

late List<Application> _deviceApps;

void initPermanentListenerForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'nitmgpt_service',
      channelName: 'NITMGPT Service',
      channelDescription: 'Keeps notification filtering running',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.nothing(),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> startPermanentListenerForegroundTask() async {
  initPermanentListenerForegroundTask();

  if (await FlutterForegroundTask.isRunningService) {
    return;
  }

  await FlutterForegroundTask.startService(
    serviceId: nitmForegroundServiceId,
    notificationTitle: 'NITMGPT SERVICE',
    notificationText: 'running...',
    callback: permanentListenerStartCallback,
  );
}

Future<void> stopPermanentListenerForegroundTask() {
  return FlutterForegroundTask.stopService();
}

void sendPromptApiKeyToMain() {
  FlutterForegroundTask.sendDataToMain({
    'action': ForegroundTaskAction.promptApiKey,
  });
}

void sendUpdateRecordsToMain() {
  FlutterForegroundTask.sendDataToMain({
    'action': ForegroundTaskAction.updateRecords,
  });
}

@pragma('vm:entry-point')
void permanentListenerStartCallback() {
  FlutterForegroundTask.setTaskHandler(PermanentListenerTaskHandler());
}

class PermanentListenerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    await initFirebase();

    _deviceApps =
        await DeviceApps.getInstalledApplications(includeSystemApps: true);

    await NotificationsListener.initialize(
      callbackHandle: handleNotificationListener,
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {}
}


Future<GPTResponse?> _inquireGPT(String question, Settings? settings,
    {Future<void> Function()? onRequestSuccess}) async {
  final openAI = OpenAI.instance.build(
    token: settings?.openAiKey,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 8),
      connectTimeout: const Duration(seconds: 8),
      proxyUrl: settings != null && settings.proxyUri != ''
          ? settings.proxyUri
          : null,
    ),
    isLogger: true,
  );

  final request = CompleteText(
    prompt: question,
    model: kTextDavinci3,
    maxTokens: 200,
  );

  CTResponse? result =
      await openAI.onCompletion(request: request).then((value) async {
    if (onRequestSuccess != null) await onRequestSuccess();
    return value;
  }).catchError((err) {
    log('$err');
    return null;
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

Future<bool> _limited(Settings settings) async {
  bool noLimit = settings.limitTimestamp == null,
      overLimitTime = !noLimit &&
          DateTime.now().difference(settings.limitTimestamp!) >
              const Duration(hours: 24);
  if (noLimit || overLimitTime) {
    await realm.writeAsync(() {
      settings.limitTimestamp = DateTime.now();
      settings.limitCounter = 0;
    });
  }

  if (settings.limitCounter != null &&
      settings.limitCounter! > settings.presetLimit) {
    return true;
  }

  return false;
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

  bool isRemoved = adRemoved || spamRemoved;
  return isRemoved;
}

@pragma('vm:entry-point')
handleNotificationListener(NotificationEvent event) async {
  try {
    Settings settings = getSettingInstance();

    if (settings.openAiKey == null || settings.openAiKey == '') {
      if (_isUnsetApiKey) {
        _isUnsetApiKey = false;
        sendPromptApiKeyToMain();
      }
      return;
    }

    if (settings.ignoredApps.contains(event.packageName)) {
      return;
    }

    if (await _limited(settings)) {
      return;
    }

    Application? app = _deviceApps.firstWhereOrNull(
        (element) => element.packageName == event.packageName);

    if (app != null && app.systemApp && settings.ignoreSystemApps) {
      return;
    }

    final notificationText =
        '${event.title ?? ''} ${event.text ?? ''}'.trim();
    final question = buildClassificationPrompt(
      notificationText,
      formatFieldDefinitions(settings),
    );
    log(question, name: 'permanent_listener_service');

    var answer = await _inquireGPT(
      question,
      settings,
      onRequestSuccess: () async {
        await realm.writeAsync(() {
          settings.limitCounter =
              settings.limitCounter == null ? 0 : settings.limitCounter! + 1;
        });
      },
    );

    if (answer != null) {
      bool isRemoved = _determineRemove(answer, settings);
      log("Notification removed: $isRemoved");

      if (isRemoved) {
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

        RealmResults<RecordedApp> result =
            realm.query<RecordedApp>('packageName == \$0', [event.packageName]);

        await realm.writeAsync(() {
          if (result.isEmpty) {
            realm.add(
                RecordedApp(ObjectId(), event.packageName!, records: [record]));
          } else {
            result.first.records.insert(0, record);
          }
        });

        sendUpdateRecordsToMain();
      }
    }
  } catch (e, stackTrace) {
    log(e.toString(), name: 'permanent_listener_service');
    FirebaseCrashlytics.instance.recordError(e, stackTrace, fatal: true);
  }
}
