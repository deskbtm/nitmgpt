import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:nitmgpt/permanent_listener_service/notification_handler.dart';

class BackgroundServiceAction {
  static const updateRecords = 'update_records';
  static const stopService = 'stopService';
  static const reloadGemma = 'reload_gemma';
  static const setAutoStartOnBoot = 'set_auto_start_on_boot';
}

const nitmForegroundServiceId = 888;
const nitmServiceChannelId = 'nitmgpt_service';

late ServiceInstance _backgroundService;
bool _backgroundServiceConfigured = false;

AndroidConfiguration _androidConfiguration({required bool autoStartOnBoot}) {
  return AndroidConfiguration(
    onStart: permanentListenerServiceMain,
    autoStart: true,
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

Future<void> configurePermanentListenerBackgroundService({
  bool autoStartOnBoot = true,
}) async {
  if (_backgroundServiceConfigured) {
    return;
  }

  final service = FlutterBackgroundService();

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

  await service.configure(
    androidConfiguration: _androidConfiguration(autoStartOnBoot: autoStartOnBoot),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );

  _backgroundServiceConfigured = true;
}

/// Persists boot auto-start in the FBS native config (SharedPreferences).
Future<void> applyPermanentListenerAutoStartOnBoot(bool enabled) async {
  final service = FlutterBackgroundService();
  final running = await service.isRunning();
  if (running) {
    service.invoke(BackgroundServiceAction.setAutoStartOnBoot, {
      'value': enabled,
    });
    return;
  }

  await service.configure(
    androidConfiguration: _androidConfiguration(autoStartOnBoot: enabled),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
  _backgroundServiceConfigured = true;
}

Future<void> stopPermanentListenerBackgroundService() async {
  FlutterBackgroundService().invoke(BackgroundServiceAction.stopService);
}

void sendUpdateRecordsToMain() {
  _backgroundService.invoke(BackgroundServiceAction.updateRecords);
}

@pragma('vm:entry-point')
void permanentListenerServiceMain(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  _backgroundService = service;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on(BackgroundServiceAction.stopService).listen((event) async {
    await disposePermanentListenerRuntime();
    service.stopSelf();
  });

  service.on(BackgroundServiceAction.reloadGemma).listen((event) async {
    await reloadPermanentListenerGemma();
  });

  service.on(BackgroundServiceAction.setAutoStartOnBoot).listen((event) async {
    if (service is! AndroidServiceInstance) {
      return;
    }
    final enabled = event?['value'] == true;
    await service.setAutoStartOnBootMode(enabled);
  });

  try {
    await initPermanentListenerRuntime();
    await NotificationsListener.initialize(
      callbackHandle: handleNotificationListener,
    );
    log('Permanent listener service started', name: 'permanent_listener_service');
  } catch (error, stackTrace) {
    log(
      'Failed to start permanent listener service: $error',
      name: 'permanent_listener_service',
      stackTrace: stackTrace,
    );
  }
}

@pragma('vm:entry-point')
void handleNotificationListener(NotificationEvent event) {
  log(
    'Notification received: package=${event.packageName} '
    'title=${event.title} text=${event.text}',
    name: 'permanent_listener_service',
  );
  unawaited(
    handlePermanentListenerNotification(event, sendUpdateRecordsToMain),
  );
}
