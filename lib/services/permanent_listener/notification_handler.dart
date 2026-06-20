import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/services/permanent_listener/background_settings.dart';
import 'package:nitmgpt/services/permanent_listener/gemma_classifier.dart';
import 'package:nitmgpt/services/permanent_listener/gpt_response.dart';
import 'package:nitmgpt/services/permanent_listener/permanent_listener_actions.dart';
import 'package:realm/realm.dart';

String _truncateLog(String? value, {int maxLen = 120}) {
  if (value == null || value.isEmpty) {
    return '';
  }
  if (value.length <= maxLen) {
    return value;
  }
  return '${value.substring(0, maxLen)}…';
}

/// Logs a raw notification event as soon as the background callback receives it.
void logNotificationReceived(NotificationEvent event) {
  logPermanentListener(
    'Notification received: '
    'package=${event.packageName} '
    'id=${event.id} '
    'uid=${event.uid} '
    'key=${event.key} '
    'channel=${event.channelId} '
    'ongoing=${event.isOngoing} '
    'title=${_truncateLog(event.title)} '
    'text=${_truncateLog(event.text)}',
  );
}

void _logNotificationSkipped(String reason, {String? packageName}) {
  final suffix = packageName == null ? '' : ' package=$packageName';
  logPermanentListener('Notification skipped:$suffix reason=$reason');
}

final PermanentListenerGemmaClassifier permanentListenerGemmaClassifier =
    PermanentListenerGemmaClassifier();
final Map<String, bool> _systemAppCache = {};

/// Serializes notification handling (filter → classify → persist).
/// Chained on [_notificationQueue] so bursts are processed FIFO, one at a time.
Future<void> _notificationQueue = Future<void>.value();

/// Count of events not yet dequeued (includes the one currently processing).
int _notificationsWaiting = 0;

/// Public entry: append [event] to the processing queue.
///
/// Android may deliver many notifications at once; the on-device model and Realm
/// writes must not run concurrently. Call this from the listener callback instead
/// of invoking [_processPermanentListenerNotification] directly.
void enqueuePermanentListenerNotification(
  NotificationEvent event,
  void Function() onRecordsUpdated,
) {
  _notificationsWaiting++;
  if (_notificationsWaiting > 1) {
    logPermanentListener(
      'Notification queued: package=${event.packageName} waiting=$_notificationsWaiting',
    );
  }

  _notificationQueue = _notificationQueue.then((_) async {
    _notificationsWaiting--;
    try {
      await _processPermanentListenerNotification(event, onRecordsUpdated);
    } catch (error, stackTrace) {
      logPermanentListener(
        'Notification processing error: $error',
        stackTrace: stackTrace,
      );
    }
  });
}

Future<void> initPermanentListenerRuntime() async {
  await permanentListenerGemmaClassifier.init();
  logPermanentListener('Permanent listener service ready');
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
  final limitTimestamp = settings.limitTimestamp;
  if (limitTimestamp == null ||
      DateTime.now().difference(limitTimestamp) > const Duration(hours: 24)) {
    await realm.writeAsync(() {
      settings.limitTimestamp = DateTime.now();
      settings.limitCounter = 0;
    });
  }

  final counter = settings.limitCounter;
  return counter != null && counter > settings.presetLimit;
}

bool _determineRemove(GPTResponse answer) {
  return answer.isAd == true || answer.isSpam == true;
}

/// Runs one notification through the full pipeline (called only from the queue).
Future<void> _processPermanentListenerNotification(
  NotificationEvent event,
  void Function() onRecordsUpdated,
) async {
  try {
    final settings = readBackgroundSettings();

    final packageName = event.packageName;
    if (packageName == null) {
      _logNotificationSkipped('missing packageName');
      return;
    }

    // --- fast filters (no model call) ---

    if (settings.ignoredApps.contains(packageName)) {
      _logNotificationSkipped('ignored app', packageName: packageName);
      return;
    }

    // Ongoing / foreground-service notifications — skip by default.
    if (isPersistentNotification(event)) {
      _logNotificationSkipped('ongoing notification', packageName: packageName);
      return;
    }

    if (await _limited(settings)) {
      _logNotificationSkipped('daily limit reached', packageName: packageName);
      return;
    }

    if (settings.ignoreSystemApps && await _isSystemApp(packageName)) {
      _logNotificationSkipped('system app', packageName: packageName);
      return;
    }

    final notificationText =
        '${event.title ?? ''} ${event.text ?? ''}'.trim();

    if (!permanentListenerGemmaClassifier.isReady) {
      _logNotificationSkipped('classifier not ready', packageName: packageName);
      return;
    }

    logPermanentListener(
      'Notification processing: package=$packageName '
      'text=${_truncateLog(notificationText)}',
    );

    // --- on-device classification (also serialized inside classifier) ---

    final answer = await permanentListenerGemmaClassifier.classifyNotification(
      notificationText: notificationText,
      settings: settings,
    );

    if (answer == null) {
      _logNotificationSkipped('classification returned null', packageName: packageName);
      return;
    }

    logPermanentListener(
      'Notification classified: package=$packageName '
      'isAd=${answer.isAd} adProb=${answer.adProbability} '
      'isSpam=${answer.isSpam} spamProb=${answer.spamProbability}',
    );

    await realm.writeAsync(() {
      settings.limitCounter = (settings.limitCounter ?? 0) + 1;
    });

    final isRemoved = _determineRemove(answer);
    logPermanentListener(
      'Notification remove decision: package=$packageName removed=$isRemoved',
    );

    if (!isRemoved) {
      return;
    }

    // --- ad/spam: cancel shade notification and persist record ---

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
    logPermanentListener(
      'Notification record saved: package=$packageName key=$key',
    );
  } catch (error, stackTrace) {
    logPermanentListener('Notification handler error: $error');
    logPermanentListener('$stackTrace');
  }
}
