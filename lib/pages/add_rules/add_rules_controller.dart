import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:nitmgpt/models/rule.dart';

class RulesController extends GetxController {
  static RulesController get to => Get.find();

  final box = GetStorage();

  final rules = <Rule>[].obs;

  late Box<Rule> rulesBox;
  Future<bool> addRule(Rule rule) async {
    if (rulesBox.values.where((element) {
      return element.packageName == rule.packageName;
    }).isNotEmpty) {
      return false;
    }

    rules.add(rule);
    await rulesBox.add(rule);

    return true;
  }

  Future<void> updateRule(Rule rule) async {
    int index = rulesBox.values
        .toList()
        .lastIndexWhere((element) => element.packageName == rule.packageName);

    await rulesBox.putAt(index, rule);
    rules[index] = rule;
  }

  Future<void> deleteRule(Rule rule) async {
    int index = rulesBox.values
        .toList()
        .lastIndexWhere((element) => element.packageName == rule.packageName);

    await rulesBox.deleteAt(index);
    rules.removeAt(index);
  }

  Rule? findRule(String packageName) {
    return rules.firstWhereOrNull((p0) => p0.packageName == packageName);
  }

  @override
  void onInit() async {
    rulesBox = await Hive.openBox<Rule>('rules');

    rules.addAll(rulesBox.values);

    super.onInit();
  }

  @override
  void onClose() {
    Get.printInfo(info: 'Rules: onClose');

    super.onClose();
  }
}
