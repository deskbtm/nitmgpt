import 'dart:typed_data';

import 'package:hive/hive.dart';
part 'rule.g.dart';

@HiveType(typeId: 1)
class Rule extends HiveObject {
  @HiveField(0)
  late String appName;

  @HiveField(1)
  late String packageName;

  @HiveField(2)
  late String callbackUrl;

  @HiveField(3)
  late String matchPattern;

  @HiveField(4)
  late String callbackHttpMethod;

  @HiveField(5)
  late Uint8List icon;
}
