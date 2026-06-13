import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static late FlutterLocalNotificationsPlugin plugin;
  static late NotificationDetails androidDetails;

  static Future<void> init() async {
    plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('notification');
    const initSettings = InitializationSettings(android: android);
    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    const channel = AndroidNotificationChannel(
      'default',
      'Default',
      importance: Importance.defaultImportance,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showNotification({
    String channelId = 'default',
    int index = 0,
    required String channelName,
    required String title,
    String? subTitle,
    String? payload,
    int maxProgress = 100,
    int progress = 0,
    bool ongoing = false,
    bool onlyAlertOnce = false,
    bool showProgress = false,
    bool indeterminate = false,
    bool autoCancel = false,
    bool channelShowBadge = false,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    NotificationVisibility visibility = NotificationVisibility.public,
  }) async {
    final android = AndroidNotificationDetails(
      channelId,
      channelName,
      priority: priority,
      importance: importance,
      ongoing: ongoing,
      channelShowBadge: channelShowBadge,
      autoCancel: autoCancel,
      onlyAlertOnce: onlyAlertOnce,
      showProgress: showProgress,
      indeterminate: indeterminate,
      visibility: visibility,
      maxProgress: maxProgress,
      color: const Color(0xFF007AFF),
      progress: progress,
    );
    androidDetails = NotificationDetails(android: android);
    await plugin.show(
      id: index,
      title: title,
      body: subTitle,
      notificationDetails: androidDetails,
      payload: payload,
    );
  }
}
