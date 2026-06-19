import 'dart:async';

import 'package:nitmgpt/core/idle_scheduler.dart';
import 'package:nitmgpt/services/local_notification.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs non-critical startup work after the UI has had time to settle.
void scheduleDeferredAppBootstrap() {
  scheduleIdleStartupTask(_runDeferredBootstrap);
}

Future<void> _runDeferredBootstrap() async {
  unawaited(LocalNotification.init());
  unawaited(Permission.notification.request());
}
