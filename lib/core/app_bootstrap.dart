import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/notification_utils.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs non-critical startup work after the first frame is painted.
void scheduleDeferredAppBootstrap() {
  SchedulerBinding.instance.scheduleFrameCallback((_) {
    unawaited(_runDeferredBootstrap());
  });
}

Future<void> _runDeferredBootstrap() async {
  await Future.wait<void>([
    ensureFlutterGemmaInitialized(),
    LocalNotification.init(),
    Permission.notification.request().then((_) {}),
  ]);
}
