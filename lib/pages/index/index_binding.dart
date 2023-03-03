import 'package:get/get.dart';
import 'index_controller.dart';

class IndexBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(IndexController(), permanent: true);
  }
}
