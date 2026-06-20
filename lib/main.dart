import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:nitmgpt/app/nitm.dart';
import 'package:nitmgpt/core/app_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandlers();
  runApp(const NITM());
  scheduleDeferredAppBootstrap();
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log(
      details.exceptionAsString(),
      name: 'flutter',
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log('$error', name: 'flutter', stackTrace: stack);
    return true;
  };
}
