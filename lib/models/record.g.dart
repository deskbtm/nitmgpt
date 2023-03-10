// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'record.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class Record extends _Record with RealmEntity, RealmObjectBase, RealmObject {
  Record(
    ObjectId id, {
    bool? isAd,
    double? adProbability,
    bool? isSpam,
    double? spamProbability,
    int? timestamp,
    DateTime? createTime,
    String? packageName,
    String? appName,
    String? notificationText,
    String? notificationTitle,
    String? uid,
    String? notificationKey,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'isAd', isAd);
    RealmObjectBase.set(this, 'adProbability', adProbability);
    RealmObjectBase.set(this, 'isSpam', isSpam);
    RealmObjectBase.set(this, 'spamProbability', spamProbability);
    RealmObjectBase.set(this, 'timestamp', timestamp);
    RealmObjectBase.set(this, 'createTime', createTime);
    RealmObjectBase.set(this, 'packageName', packageName);
    RealmObjectBase.set(this, 'appName', appName);
    RealmObjectBase.set(this, 'notificationText', notificationText);
    RealmObjectBase.set(this, 'notificationTitle', notificationTitle);
    RealmObjectBase.set(this, 'uid', uid);
    RealmObjectBase.set(this, 'notificationKey', notificationKey);
  }

  Record._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  bool? get isAd => RealmObjectBase.get<bool>(this, 'isAd') as bool?;
  @override
  set isAd(bool? value) => RealmObjectBase.set(this, 'isAd', value);

  @override
  double? get adProbability =>
      RealmObjectBase.get<double>(this, 'adProbability') as double?;
  @override
  set adProbability(double? value) =>
      RealmObjectBase.set(this, 'adProbability', value);

  @override
  bool? get isSpam => RealmObjectBase.get<bool>(this, 'isSpam') as bool?;
  @override
  set isSpam(bool? value) => RealmObjectBase.set(this, 'isSpam', value);

  @override
  double? get spamProbability =>
      RealmObjectBase.get<double>(this, 'spamProbability') as double?;
  @override
  set spamProbability(double? value) =>
      RealmObjectBase.set(this, 'spamProbability', value);

  @override
  int? get timestamp => RealmObjectBase.get<int>(this, 'timestamp') as int?;
  @override
  set timestamp(int? value) => RealmObjectBase.set(this, 'timestamp', value);

  @override
  DateTime? get createTime =>
      RealmObjectBase.get<DateTime>(this, 'createTime') as DateTime?;
  @override
  set createTime(DateTime? value) =>
      RealmObjectBase.set(this, 'createTime', value);

  @override
  String? get packageName =>
      RealmObjectBase.get<String>(this, 'packageName') as String?;
  @override
  set packageName(String? value) =>
      RealmObjectBase.set(this, 'packageName', value);

  @override
  String? get appName =>
      RealmObjectBase.get<String>(this, 'appName') as String?;
  @override
  set appName(String? value) => RealmObjectBase.set(this, 'appName', value);

  @override
  String? get notificationText =>
      RealmObjectBase.get<String>(this, 'notificationText') as String?;
  @override
  set notificationText(String? value) =>
      RealmObjectBase.set(this, 'notificationText', value);

  @override
  String? get notificationTitle =>
      RealmObjectBase.get<String>(this, 'notificationTitle') as String?;
  @override
  set notificationTitle(String? value) =>
      RealmObjectBase.set(this, 'notificationTitle', value);

  @override
  String? get uid => RealmObjectBase.get<String>(this, 'uid') as String?;
  @override
  set uid(String? value) => RealmObjectBase.set(this, 'uid', value);

  @override
  String? get notificationKey =>
      RealmObjectBase.get<String>(this, 'notificationKey') as String?;
  @override
  set notificationKey(String? value) =>
      RealmObjectBase.set(this, 'notificationKey', value);

  @override
  Stream<RealmObjectChanges<Record>> get changes =>
      RealmObjectBase.getChanges<Record>(this);

  @override
  Record freeze() => RealmObjectBase.freezeObject<Record>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Record._);
    return const SchemaObject(ObjectType.realmObject, Record, 'Record', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('isAd', RealmPropertyType.bool, optional: true),
      SchemaProperty('adProbability', RealmPropertyType.double, optional: true),
      SchemaProperty('isSpam', RealmPropertyType.bool, optional: true),
      SchemaProperty('spamProbability', RealmPropertyType.double,
          optional: true),
      SchemaProperty('timestamp', RealmPropertyType.int, optional: true),
      SchemaProperty('createTime', RealmPropertyType.timestamp, optional: true),
      SchemaProperty('packageName', RealmPropertyType.string, optional: true),
      SchemaProperty('appName', RealmPropertyType.string, optional: true),
      SchemaProperty('notificationText', RealmPropertyType.string,
          optional: true),
      SchemaProperty('notificationTitle', RealmPropertyType.string,
          optional: true),
      SchemaProperty('uid', RealmPropertyType.string, optional: true),
      SchemaProperty('notificationKey', RealmPropertyType.string,
          optional: true),
    ]);
  }
}

class RecordedApp extends _RecordedApp
    with RealmEntity, RealmObjectBase, RealmObject {
  RecordedApp(
    ObjectId id,
    String packageName, {
    Iterable<Record> records = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'packageName', packageName);
    RealmObjectBase.set<RealmList<Record>>(
        this, 'records', RealmList<Record>(records));
  }

  RecordedApp._();

  @override
  ObjectId get id => RealmObjectBase.get<ObjectId>(this, 'id') as ObjectId;
  @override
  set id(ObjectId value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get packageName =>
      RealmObjectBase.get<String>(this, 'packageName') as String;
  @override
  set packageName(String value) =>
      RealmObjectBase.set(this, 'packageName', value);

  @override
  RealmList<Record> get records =>
      RealmObjectBase.get<Record>(this, 'records') as RealmList<Record>;
  @override
  set records(covariant RealmList<Record> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<RecordedApp>> get changes =>
      RealmObjectBase.getChanges<RecordedApp>(this);

  @override
  RecordedApp freeze() => RealmObjectBase.freezeObject<RecordedApp>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(RecordedApp._);
    return const SchemaObject(
        ObjectType.realmObject, RecordedApp, 'RecordedApp', [
      SchemaProperty('id', RealmPropertyType.objectid, primaryKey: true),
      SchemaProperty('packageName', RealmPropertyType.string),
      SchemaProperty('records', RealmPropertyType.object,
          linkTarget: 'Record', collectionType: RealmCollectionType.list),
    ]);
  }
}
