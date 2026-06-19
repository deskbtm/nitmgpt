import 'package:realm/realm.dart';

part 'kv_entry.g.dart';

@RealmModel()
class _KvEntry {
  @PrimaryKey()
  late String key;

  String? stringValue;
  bool? boolValue;
  int? intValue;
  double? doubleValue;
}
