// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kv_entry.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class KvEntry extends _KvEntry with RealmEntity, RealmObjectBase, RealmObject {
  KvEntry(
    String key, {
    String? stringValue,
    bool? boolValue,
    int? intValue,
    double? doubleValue,
  }) {
    RealmObjectBase.set(this, 'key', key);
    RealmObjectBase.set(this, 'stringValue', stringValue);
    RealmObjectBase.set(this, 'boolValue', boolValue);
    RealmObjectBase.set(this, 'intValue', intValue);
    RealmObjectBase.set(this, 'doubleValue', doubleValue);
  }

  KvEntry._();

  @override
  String get key => RealmObjectBase.get<String>(this, 'key') as String;
  @override
  set key(String value) => RealmObjectBase.set(this, 'key', value);

  @override
  String? get stringValue =>
      RealmObjectBase.get<String>(this, 'stringValue') as String?;
  @override
  set stringValue(String? value) =>
      RealmObjectBase.set(this, 'stringValue', value);

  @override
  bool? get boolValue =>
      RealmObjectBase.get<bool>(this, 'boolValue') as bool?;
  @override
  set boolValue(bool? value) => RealmObjectBase.set(this, 'boolValue', value);

  @override
  int? get intValue => RealmObjectBase.get<int>(this, 'intValue') as int?;
  @override
  set intValue(int? value) => RealmObjectBase.set(this, 'intValue', value);

  @override
  double? get doubleValue =>
      RealmObjectBase.get<double>(this, 'doubleValue') as double?;
  @override
  set doubleValue(double? value) =>
      RealmObjectBase.set(this, 'doubleValue', value);

  @override
  Stream<RealmObjectChanges<KvEntry>> get changes =>
      RealmObjectBase.getChanges<KvEntry>(this);

  @override
  KvEntry freeze() => RealmObjectBase.freezeObject<KvEntry>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(KvEntry._);
    return const SchemaObject(ObjectType.realmObject, KvEntry, 'KvEntry', [
      SchemaProperty('key', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('stringValue', RealmPropertyType.string, optional: true),
      SchemaProperty('boolValue', RealmPropertyType.bool, optional: true),
      SchemaProperty('intValue', RealmPropertyType.int, optional: true),
      SchemaProperty('doubleValue', RealmPropertyType.double, optional: true),
    ]);
  }
}
