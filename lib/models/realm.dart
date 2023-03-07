import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:realm/realm.dart';

var _config = Configuration.local(
  [
    Record.schema,
    Settings.schema,
    RuleFields.schema,
  ],
  schemaVersion: 7,
);

var realm = Realm(_config);
