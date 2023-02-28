import 'package:hive/hive.dart';
part 'record.g.dart';

@HiveType(typeId: 0)
class Record extends HiveObject {
  ///whether it is an advertisement
  @HiveField(1)
  late bool isAd;

  ///the probability that this sentence is classified as an advertisement
  @HiveField(2)
  late double adProbability;

  @HiveField(3)
  late bool isSpam;

  @HiveField(4)
  late double spamProbability;

  @HiveField(5)
  late int timestamp;

  @HiveField(6)
  late DateTime createTime;

  @HiveField(7)
  late String packageName;

  @HiveField(8)
  late String appName;

  @HiveField(9)
  late String notificationText;

  @HiveField(10)
  late String notificationTitle;

  @HiveField(11)
  late String uid;

  @HiveField(12)
  late String notificationKey;

  @HiveField(13)
  late bool removed;

  // Map<String, dynamic> toMap() {
  //   return {
  //     "amount": amount,
  //     "timestamp": timestamp,
  //     "createTime": createTime.toIso8601String(),
  //     "packageName": packageName,
  //     "appName": appName,
  //     "notificationText": notificationText,
  //     "notificationTitle": notificationTitle,
  //     "uid": uid,
  //   };
  // }
}
