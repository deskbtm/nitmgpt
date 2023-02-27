import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/double_pop_exit.dart';
import 'package:unicons/unicons.dart';
import 'index_controller.dart';

class IndexPage extends GetView<IndexController> {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DoublePopExit(
      child: Scaffold(
        body: Navigator(
          key: Get.nestedKey(1),
          initialRoute: '/home',
          onGenerateRoute: controller.onGenerateRoute,
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     // RuleF.selectedApp.value = null;
        //     Get.toNamed('/add_rules', parameters: {"action": "create"});
        //   },
        //   tooltip: 'Add match rules',
        //   child: const Icon(
        //     UniconsLine.plus,
        //   ),
        // ),
        bottomNavigationBar: Obx(
          () => NavigationBar(
            destinations: [
              NavigationDestination(
                icon: const Icon(UniconsLine.monitor_heart_rate),
                label: 'Home'.tr,
              ),
              NavigationDestination(
                icon: const Icon(UniconsLine.setting),
                label: 'Settings'.tr,
              )
            ],
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.changePage,
          ),
        ),
      ),
    );
  }
}
