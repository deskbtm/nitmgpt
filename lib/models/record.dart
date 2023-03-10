import 'package:realm/realm.dart';
part 'record.g.dart';

@RealmModel()
class _Record {
  @PrimaryKey()
  late ObjectId id;

  bool? isAd;

  /// The probability that this sentence is classified as an advertisement
  double? adProbability;

  bool? isSpam;

  double? spamProbability;

  int? timestamp;

  DateTime? createTime;

  String? packageName;

  String? appName;

  String? notificationText;

  String? notificationTitle;

  String? uid;

  String? notificationKey;
}

@RealmModel()
class _RecordedApp {
  @PrimaryKey()
  late ObjectId id;

  late String packageName;

  late List<_Record> records;
}
