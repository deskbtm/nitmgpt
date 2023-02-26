import 'package:get/get.dart';

import 'add_rules_controller.dart';

class AddRulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RulesController());
  }
}
