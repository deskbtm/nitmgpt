import 'dart:developer';

/// IPC action names between UI ([FlutterBackgroundService]) and Service ([ServiceInstance]).
class BackgroundServiceAction {
  static const updateRecords = 'update_records';
  static const stopService = 'stopService';
  static const reloadGemma = 'reload_gemma';
  static const setAutoStartOnBoot = 'set_auto_start_on_boot';
}

const nitmForegroundServiceId = 888;
const nitmServiceChannelId = 'nitmgpt_service';
const kPermanentListenerLog = 'permanent_listener_service';

void logPermanentListener(String message, {StackTrace? stackTrace}) {
  log(message, name: kPermanentListenerLog, stackTrace: stackTrace);
}
