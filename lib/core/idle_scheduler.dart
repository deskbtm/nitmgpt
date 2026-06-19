import 'dart:async';

import 'package:flutter/scheduler.dart';

/// Runs [task] after [delay] so the first scroll gestures stay smooth.
Future<void> runAfterStartupGracePeriod(
  Future<void> Function() task, {
  Duration delay = const Duration(milliseconds: 1500),
}) async {
  await Future.delayed(delay);
  await task();
}

/// Schedules [task] on the first idle frame after [delay].
void scheduleIdleStartupTask(
  Future<void> Function() task, {
  Duration delay = const Duration(milliseconds: 2000),
}) {
  Future<void>.delayed(delay, () {
    SchedulerBinding.instance.scheduleTask(
      () async {
        await task();
        return null;
      },
      Priority.idle,
    );
  });
}
