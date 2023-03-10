import 'dart:ui';
import 'dart:developer';
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

bool _isUnsetApiKey = true;

late List<Application> _deviceApps;
late ServiceInstance _backgroundService;

String _getFieldsMeans(Settings? settings) {
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
        _backgroundService.invoke("prompt_api_key");
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

    // Exclude system apps.
    if (app != null && app.systemApp && settings.ignoreSystemApps) {
      return;
    }

    String fieldsMeans = _getFieldsMeans(settings);
    String question =
        'Determine "${event.title} ${event.text}", $fieldsMeans, only return json.';
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

  _deviceApps =
      await DeviceApps.getInstalledApplications(includeSystemApps: true);

  await NotificationsListener.initialize(
    callbackHandle: handleNotificationListener,
  );
}
