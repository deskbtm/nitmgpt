import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class HomeController extends FullLifeCycleController
    with FullLifeCycleMixin, GetTickerProviderStateMixin {
  static HomeController get to => Get.find();

  final _watchController = WatcherController.to;

  TabController? tabController;

  _setDetectedApps() {
    _watchController.detectedApps.value = _watchController.getDetectedApps();
  }

  void _onForegroundTaskData(Object data) {
    if (data is Map &&
        data['action'] == ForegroundTaskAction.updateRecords) {
      _setDetectedApps();
      update();
    }
  }

  @override
  void onInit() {
    super.onInit();

    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);

    once(_watchController.deviceApps, (callback) {
      _setDetectedApps();
    });

    ever(_watchController.detectedApps, (callback) {
      tabController = TabController(
          length: _watchController.detectedApps.length,
          vsync: this,
          initialIndex: 0);

      update();
    });
  }

  @override
  void onClose() {
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    tabController?.dispose();
    super.onClose();
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {
    update();
  }

  @override
  void onHidden() {}
}
