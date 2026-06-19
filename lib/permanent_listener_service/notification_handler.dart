import 'dart:developer';

import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/permanent_listener_service/background_settings.dart';
import 'package:nitmgpt/permanent_listener_service/gemma_classifier.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:realm/realm.dart';

final PermanentListenerGemmaClassifier permanentListenerGemmaClassifier =
    PermanentListenerGemmaClassifier();
final Map<String, bool> _systemAppCache = {};

Future<void> initPermanentListenerRuntime() async {
  await permanentListenerGemmaClassifier.init();
  log('Permanent listener service ready', name: 'permanent_listener_service');
}

Future<void> disposePermanentListenerRuntime() async {
  await permanentListenerGemmaClassifier.dispose();
}

Future<void> reloadPermanentListenerGemma() async {
  await permanentListenerGemmaClassifier.reload();
}

Future<bool> _isSystemApp(String packageName) async {
  final cached = _systemAppCache[packageName];
  if (cached != null) {
    return cached;
  }
  final result = await InstalledApps.isSystemApp(packageName) ?? false;
  _systemAppCache[packageName] = result;
  return result;
}

Future<bool> _limited(Settings settings) async {
  final noLimit = settings.limitTimestamp == null;
  final overLimitTime = !noLimit &&
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
  var adRemoved = false;
  var spamRemoved = false;
  final adProbability = settings?.presetAdProbability;
  final spamProbability = settings?.presetSpamProbability;

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

  return adRemoved || spamRemoved;
}

Future<void> handlePermanentListenerNotification(
  NotificationEvent event,
  void Function() onRecordsUpdated,
) async {
  try {
    final settings = readBackgroundSettings();

    final packageName = event.packageName;
    if (packageName == null) {
      return;
    }

    if (settings.ignoredApps.contains(packageName)) {
      return;
    }

    if (await _limited(settings)) {
      return;
    }

    if (settings.ignoreSystemApps && await _isSystemApp(packageName)) {
      return;
    }

    final notificationText =
        '${event.title ?? ''} ${event.text ?? ''}'.trim();

    if (!permanentListenerGemmaClassifier.isReady) {
      log(
        'Gemma classifier not ready — notification skipped',
        name: 'permanent_listener_service',
      );
      return;
    }

    final answer = await permanentListenerGemmaClassifier.classifyNotification(
      notificationText: notificationText,
      settings: settings,
    );

    if (answer == null) {
      return;
    }

    await realm.writeAsync(() {
      settings.limitCounter =
          settings.limitCounter == null ? 0 : settings.limitCounter! + 1;
    });

    final isRemoved = _determineRemove(answer, settings);
    log('Notification removed: $isRemoved', name: 'permanent_listener_service');

    if (!isRemoved) {
      return;
    }

    final key = event.key;
    if (key != null) {
      await NotificationsListener.cancelNotification(key);
    }

    final record = Record(
      ObjectId(),
      isAd: answer.isAd,
      adProbability: answer.adProbability,
      isSpam: answer.isSpam,
      spamProbability: answer.spamProbability,
      packageName: packageName,
      notificationKey: key,
      notificationText: event.text,
      notificationTitle: event.title,
      timestamp: event.timestamp,
      createTime: event.createAt,
      uid: event.uniqueId,
    );

    final result =
        realm.query<RecordedApp>('packageName == \$0', [packageName]);

    await realm.writeAsync(() {
      if (result.isEmpty) {
        realm.add(
          RecordedApp(ObjectId(), packageName, records: [record]),
        );
      } else {
        result.first.records.insert(0, record);
      }
    });

    onRecordsUpdated();
  } catch (error, stackTrace) {
    log('$error', name: 'permanent_listener_service');
    log('$stackTrace', name: 'permanent_listener_service');
  }
}
