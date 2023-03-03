import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/pages/home/home.dart';
import 'package:nitmgpt/pages/settings/settings.dart';

class IndexController extends GetxController {
  static IndexController get to => Get.find();

  var currentIndex = 0.obs;

  final pages = <String>['/home', '/settings'];

  void changePage(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
      Get.toNamed(pages[index], id: 1);
    }
  }

  Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/home':
        return GetPageRoute(
          settings: settings,
          transition: Transition.leftToRight,
          page: () => HomePage(),
        );
      case '/settings':
        return GetPageRoute(
          transition: Transition.rightToLeft,
          settings: settings,
          page: () => SettingsPage(),
        );
    }
    return null;
  }
}
