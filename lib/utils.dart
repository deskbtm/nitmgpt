import 'dart:convert';

import 'models/realm.dart';
import 'models/settings.dart';

dynamic looseJSONParse(String content) {
  try {
    content = content.replaceAll("\n", "");
    var match = RegExp(r"((\[[^\}]{3,})?\{s*[^\}\{]{3,}?:.*\}([^\{]+\])?)")
        .firstMatch(content);
    String? val = match?.group(0);
    if (val != null) {
      return jsonDecode(val);
    }

    return null;
  } catch (e) {
    return null;
  }
}

Settings getSettingInstance() {
  Settings? s = realm.find<Settings>(0);
  if (s == null) {
    realm.write(() {
      realm.add(Settings(0));
    });
    s = realm.find<Settings>(0);
  }

  return s!;
}
