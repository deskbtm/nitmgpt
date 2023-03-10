import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';

class HomeController extends FullLifeCycleController
    with FullLifeCycleMixin, GetTickerProviderStateMixin {
  static HomeController get to => Get.find();

  final _watchController = WatcherController.to;

  TabController? tabController;

  _setDetectedApps() {
    _watchController.detectedApps.value = _watchController.getDetectedApps();
  }

  @override
  void onInit() {
    super.onInit();

    once(_watchController.deviceApps, (callback) {
      _setDetectedApps();
      _watchController.backgroundService
          .on('update_records')
          .listen((event) async {
        _setDetectedApps();
        update();
      });
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
}
