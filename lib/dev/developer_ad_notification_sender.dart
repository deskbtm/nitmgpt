import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/dev/developer_ad_notification_samples.dart';
import 'package:nitmgpt/notification_utils.dart';

Future<bool> sendDeveloperAdNotification(
  DeveloperAdNotificationSample sample,
) async {
  final isListening = await NotificationsListener.isRunning ?? false;
  if (!isListening) {
    Fluttertoast.showToast(msg: 'Notification listener is not running'.tr);
    return false;
  }

  await LocalNotification.init();
  await LocalNotification.showNotification(
    channelId: 'dev_ad_notifications',
    channelName: 'Dev Ad Notifications',
    index: sample.notificationId,
    title: sample.title,
    subTitle: sample.text,
  );

  Fluttertoast.showToast(msg: 'Ad notification sent'.tr);
  return true;
}
