import 'package:hive/hive.dart';
part 'record.g.dart';

@HiveType(typeId: 0)
class Record extends HiveObject {
  @HiveField(1)
  late String amount;

  @HiveField(2)
  late int timestamp;

  @HiveField(3)
  late DateTime createTime;

  @HiveField(4)
  late String packageName;

  @HiveField(5)
  late String appName;

  @HiveField(6)
  late String notificationText;

  @HiveField(7)
  late String notificationTitle;

  @HiveField(8)
  late String uid;

  // @HiveField(9)
  // late String requestStatus;

  Map<String, dynamic> toMap() {
    return {
      "amount": amount,
      "timestamp": timestamp,
      "createTime": createTime.toIso8601String(),
      "packageName": packageName,
      "appName": appName,
      "notificationText": notificationText,
      "notificationTitle": notificationTitle,
      "uid": uid,
    };
  }
}
