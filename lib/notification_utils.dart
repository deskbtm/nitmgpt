import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static late FlutterLocalNotificationsPlugin? plugin;

  static Future<void> init() async {
    plugin = FlutterLocalNotificationsPlugin();
    var android = const AndroidInitializationSettings('notification');
    var initSettings = InitializationSettings(android: android);
    await plugin?.initialize(initSettings);
  }

  static Future<void> showNotification({
    String channelId = '0',
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
    var android = AndroidNotificationDetails(
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
    var platform = NotificationDetails(android: android);
    await plugin?.show(index, title, subTitle, platform, payload: payload);
  }
}
