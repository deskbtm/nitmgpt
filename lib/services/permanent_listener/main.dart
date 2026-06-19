import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:nitmgpt/services/permanent_listener/notification_handler.dart';
import 'package:nitmgpt/services/permanent_listener/permanent_listener_actions.dart';

/// flutter_background_service [onStart] entry — runs inside the background Service.
/// Use [ServiceInstance] here only; UI uses [FlutterBackgroundService] in
/// [background_service_host.dart]. Communicate via invoke/on (see package docs).

late ServiceInstance _backgroundService;

/// Notifies the UI that records changed ([FlutterBackgroundService.on] in app code).
void sendUpdateRecordsToMain() {
  _backgroundService.invoke(BackgroundServiceAction.updateRecords);
}

@pragma('vm:entry-point')
void permanentListenerServiceMain(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  _backgroundService = service;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  service.on(BackgroundServiceAction.stopService).listen((_) async {
    await disposePermanentListenerRuntime();
    service.stopSelf();
  });

  service.on(BackgroundServiceAction.reloadGemma).listen((_) async {
    await reloadPermanentListenerGemma();
  });

  service.on(BackgroundServiceAction.setAutoStartOnBoot).listen((event) async {
    if (service is! AndroidServiceInstance) {
      return;
    }
    await service.setAutoStartOnBootMode(event?['value'] == true);
  });

  try {
    await initPermanentListenerRuntime();
    if (!permanentListenerGemmaClassifier.isReady) {
      logPermanentListener(
        'No active local model — stopping permanent listener service',
      );
      service.stopSelf();
      return;
    }

    await NotificationsListener.initialize(
      callbackHandle: handleNotificationListener,
    );
    logPermanentListener('Permanent listener service started');
  } catch (error, stackTrace) {
    logPermanentListener(
      'Failed to start permanent listener service: $error',
      stackTrace: stackTrace,
    );
  }
}

@pragma('vm:entry-point')
void handleNotificationListener(NotificationEvent event) {
  logNotificationReceived(event);
  unawaited(
    handlePermanentListenerNotification(event, sendUpdateRecordsToMain),
  );
}
