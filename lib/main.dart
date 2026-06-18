import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:nitmgpt/core/app_bootstrap.dart';
import 'package:nitmgpt/core/prefs_signal.dart';
import 'nitm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await initAppPrefs();
  runApp(const NITM());
  scheduleDeferredAppBootstrap();
}
