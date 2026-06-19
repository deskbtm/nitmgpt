import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/services/permanent_listener/main.dart'
    show permanentListenerServiceMain;
import 'package:nitmgpt/services/permanent_listener/permanent_listener_actions.dart';

export 'package:nitmgpt/services/permanent_listener/permanent_listener_actions.dart';

// flutter_background_service architecture (https://pub.dev/packages/flutter_background_service):
// - App/UI: [FlutterBackgroundService] — configure, startService, invoke, on().
// - Service: [ServiceInstance] inside [permanentListenerServiceMain] (onStart) only.
// UI and Service do not share object references; use invoke/on to communicate.

bool _backgroundServiceConfigured = false;

final _iosConfiguration = IosConfiguration(autoStart: false);

AndroidConfiguration _androidConfiguration({required bool autoStartOnBoot}) {
  return AndroidConfiguration(
    onStart: permanentListenerServiceMain,
    autoStart: false,
    autoStartOnBoot: autoStartOnBoot,
    isForegroundMode: true,
    notificationChannelId: nitmServiceChannelId,
    initialNotificationTitle: 'NITMGPT SERVICE',
    initialNotificationContent: 'running...',
    foregroundServiceNotificationId: nitmForegroundServiceId,
    foregroundServiceTypes: [
      AndroidForegroundType.dataSync,
      AndroidForegroundType.remoteMessaging,
    ],
  );
}

/// App/UI side. Registers FBS [onStart] handler and the Android notification channel.
/// Does not start the service — call [syncPermanentListenerBackgroundService] after.
Future<void> configurePermanentListenerBackgroundService({
  bool autoStartOnBoot = true,
}) async {
  if (_backgroundServiceConfigured) {
    return;
  }

  const channel = AndroidNotificationChannel(
    nitmServiceChannelId,
    'NITMGPT Service',
    description: 'Keeps notification filtering running',
    importance: Importance.low,
  );

  final notifications = FlutterLocalNotificationsPlugin();
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FlutterBackgroundService().configure(
    androidConfiguration: _androidConfiguration(autoStartOnBoot: autoStartOnBoot),
    iosConfiguration: _iosConfiguration,
  );

  _backgroundServiceConfigured = true;
}

/// App/UI side. Start, reload, or stop the background service via [FlutterBackgroundService].
Future<void> syncPermanentListenerBackgroundService() async {
  if (!_backgroundServiceConfigured) {
    logPermanentListener(
      'Permanent listener sync skipped — call configurePermanentListenerBackgroundService on UI first',
    );
    return;
  }

  final service = FlutterBackgroundService();
  final hasModel = await hasActiveLocalModelForListener();

  if (!hasModel) {
    if (await service.isRunning()) {
      stopPermanentListenerBackgroundService();
    }
    logPermanentListener(
      'Permanent listener service not started — no active local model',
    );
    return;
  }

  if (await service.isRunning()) {
    service.invoke(BackgroundServiceAction.reloadGemma);
    logPermanentListener('Permanent listener service reload requested');
    return;
  }

  final started = await service.startService();
  logPermanentListener('Permanent listener service start: $started');
}

/// Persists boot auto-start in the FBS native config (SharedPreferences).
Future<void> applyPermanentListenerAutoStartOnBoot(bool enabled) async {
  final service = FlutterBackgroundService();
  if (await service.isRunning()) {
    service.invoke(BackgroundServiceAction.setAutoStartOnBoot, {
      'value': enabled,
    });
    return;
  }

  await service.configure(
    androidConfiguration: _androidConfiguration(autoStartOnBoot: enabled),
    iosConfiguration: _iosConfiguration,
  );
  _backgroundServiceConfigured = true;
}

Future<void> stopPermanentListenerBackgroundService() async {
  FlutterBackgroundService().invoke(BackgroundServiceAction.stopService);
}
