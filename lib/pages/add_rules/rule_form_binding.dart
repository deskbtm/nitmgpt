import 'package:get/get.dart';

import 'rule_form_controller.dart';

class RuleFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RuleFormController());
  }
}
