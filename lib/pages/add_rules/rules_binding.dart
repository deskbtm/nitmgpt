import 'package:get/get.dart';
import 'rules_controller.dart';

class RulesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RulesController());
  }
}
