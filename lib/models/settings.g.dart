// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

class RuleFields extends _RuleFields
    with RealmEntity, RealmObjectBase, RealmObject {
  RuleFields(
    String isAdMeaning,
    String adProbabilityMeaning,
    String isSpamMeaning,
    String spamProbabilityMeaning,
    String sentenceMeaning,
  ) {
    RealmObjectBase.set(this, 'isAdMeaning', isAdMeaning);
    RealmObjectBase.set(this, 'adProbabilityMeaning', adProbabilityMeaning);
    RealmObjectBase.set(this, 'isSpamMeaning', isSpamMeaning);
    RealmObjectBase.set(this, 'spamProbabilityMeaning', spamProbabilityMeaning);
    RealmObjectBase.set(this, 'sentenceMeaning', sentenceMeaning);
  }

  RuleFields._();

  @override
  String get isAdMeaning =>
      RealmObjectBase.get<String>(this, 'isAdMeaning') as String;
  @override
  set isAdMeaning(String value) =>
      RealmObjectBase.set(this, 'isAdMeaning', value);

  @override
  String get adProbabilityMeaning =>
      RealmObjectBase.get<String>(this, 'adProbabilityMeaning') as String;
  @override
  set adProbabilityMeaning(String value) =>
      RealmObjectBase.set(this, 'adProbabilityMeaning', value);

  @override
  String get isSpamMeaning =>
      RealmObjectBase.get<String>(this, 'isSpamMeaning') as String;
  @override
  set isSpamMeaning(String value) =>
      RealmObjectBase.set(this, 'isSpamMeaning', value);

  @override
  String get spamProbabilityMeaning =>
      RealmObjectBase.get<String>(this, 'spamProbabilityMeaning') as String;
  @override
  set spamProbabilityMeaning(String value) =>
      RealmObjectBase.set(this, 'spamProbabilityMeaning', value);

  @override
  String get sentenceMeaning =>
      RealmObjectBase.get<String>(this, 'sentenceMeaning') as String;
  @override
  set sentenceMeaning(String value) =>
      RealmObjectBase.set(this, 'sentenceMeaning', value);

  @override
  Stream<RealmObjectChanges<RuleFields>> get changes =>
      RealmObjectBase.getChanges<RuleFields>(this);

  @override
  RuleFields freeze() => RealmObjectBase.freezeObject<RuleFields>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(RuleFields._);
    return const SchemaObject(
        ObjectType.realmObject, RuleFields, 'RuleFields', [
      SchemaProperty('isAdMeaning', RealmPropertyType.string),
      SchemaProperty('adProbabilityMeaning', RealmPropertyType.string),
      SchemaProperty('isSpamMeaning', RealmPropertyType.string),
      SchemaProperty('spamProbabilityMeaning', RealmPropertyType.string),
      SchemaProperty('sentenceMeaning', RealmPropertyType.string),
    ]);
  }
}

class Settings extends _Settings
    with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  Settings(
    int id, {
    String? proxyUri,
    String? openAiKey,
    double? presetAdProbability,
    double? presetSpamProbability,
    int presetLimit = 200,
    int? limitCounter,
    DateTime? limitTimestamp,
    RuleFields? ruleFields,
    bool? ownedApp,
    String? language,
    Iterable<String> ignoredApps = const [],
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<Settings>({
        'presetLimit': 200,
      });
    }
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'proxyUri', proxyUri);
    RealmObjectBase.set(this, 'openAiKey', openAiKey);
    RealmObjectBase.set(this, 'presetAdProbability', presetAdProbability);
    RealmObjectBase.set(this, 'presetSpamProbability', presetSpamProbability);
    RealmObjectBase.set(this, 'presetLimit', presetLimit);
    RealmObjectBase.set(this, 'limitCounter', limitCounter);
    RealmObjectBase.set(this, 'limitTimestamp', limitTimestamp);
    RealmObjectBase.set(this, 'ruleFields', ruleFields);
    RealmObjectBase.set(this, 'ownedApp', ownedApp);
    RealmObjectBase.set(this, 'language', language);
    RealmObjectBase.set<RealmList<String>>(
        this, 'ignoredApps', RealmList<String>(ignoredApps));
  }

  Settings._();

  @override
  int get id => RealmObjectBase.get<int>(this, 'id') as int;
  @override
  set id(int value) => RealmObjectBase.set(this, 'id', value);

  @override
  String? get proxyUri =>
      RealmObjectBase.get<String>(this, 'proxyUri') as String?;
  @override
  set proxyUri(String? value) => RealmObjectBase.set(this, 'proxyUri', value);

  @override
  String? get openAiKey =>
      RealmObjectBase.get<String>(this, 'openAiKey') as String?;
  @override
  set openAiKey(String? value) => RealmObjectBase.set(this, 'openAiKey', value);

  @override
  double? get presetAdProbability =>
      RealmObjectBase.get<double>(this, 'presetAdProbability') as double?;
  @override
  set presetAdProbability(double? value) =>
      RealmObjectBase.set(this, 'presetAdProbability', value);

  @override
  double? get presetSpamProbability =>
      RealmObjectBase.get<double>(this, 'presetSpamProbability') as double?;
  @override
  set presetSpamProbability(double? value) =>
      RealmObjectBase.set(this, 'presetSpamProbability', value);

  @override
  int get presetLimit => RealmObjectBase.get<int>(this, 'presetLimit') as int;
  @override
  set presetLimit(int value) => RealmObjectBase.set(this, 'presetLimit', value);

  @override
  int? get limitCounter =>
      RealmObjectBase.get<int>(this, 'limitCounter') as int?;
  @override
  set limitCounter(int? value) =>
      RealmObjectBase.set(this, 'limitCounter', value);

  @override
  DateTime? get limitTimestamp =>
      RealmObjectBase.get<DateTime>(this, 'limitTimestamp') as DateTime?;
  @override
  set limitTimestamp(DateTime? value) =>
      RealmObjectBase.set(this, 'limitTimestamp', value);

  @override
  RuleFields? get ruleFields =>
      RealmObjectBase.get<RuleFields>(this, 'ruleFields') as RuleFields?;
  @override
  set ruleFields(covariant RuleFields? value) =>
      RealmObjectBase.set(this, 'ruleFields', value);

  @override
  RealmList<String> get ignoredApps =>
      RealmObjectBase.get<String>(this, 'ignoredApps') as RealmList<String>;
  @override
  set ignoredApps(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  bool? get ownedApp => RealmObjectBase.get<bool>(this, 'ownedApp') as bool?;
  @override
  set ownedApp(bool? value) => RealmObjectBase.set(this, 'ownedApp', value);

  @override
  String? get language =>
      RealmObjectBase.get<String>(this, 'language') as String?;
  @override
  set language(String? value) => RealmObjectBase.set(this, 'language', value);

  @override
  Stream<RealmObjectChanges<Settings>> get changes =>
      RealmObjectBase.getChanges<Settings>(this);

  @override
  Settings freeze() => RealmObjectBase.freezeObject<Settings>(this);

  static SchemaObject get schema => _schema ??= _initSchema();
  static SchemaObject? _schema;
  static SchemaObject _initSchema() {
    RealmObjectBase.registerFactory(Settings._);
    return const SchemaObject(ObjectType.realmObject, Settings, 'Settings', [
      SchemaProperty('id', RealmPropertyType.int, primaryKey: true),
      SchemaProperty('proxyUri', RealmPropertyType.string, optional: true),
      SchemaProperty('openAiKey', RealmPropertyType.string, optional: true),
      SchemaProperty('presetAdProbability', RealmPropertyType.double,
          optional: true),
      SchemaProperty('presetSpamProbability', RealmPropertyType.double,
          optional: true),
      SchemaProperty('presetLimit', RealmPropertyType.int),
      SchemaProperty('limitCounter', RealmPropertyType.int, optional: true),
      SchemaProperty('limitTimestamp', RealmPropertyType.timestamp,
          optional: true),
      SchemaProperty('ruleFields', RealmPropertyType.object,
          optional: true, linkTarget: 'RuleFields'),
      SchemaProperty('ignoredApps', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('ownedApp', RealmPropertyType.bool, optional: true),
      SchemaProperty('language', RealmPropertyType.string, optional: true),
    ]);
  }
}
