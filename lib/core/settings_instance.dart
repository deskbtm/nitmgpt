import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';

Settings getSettingInstance() {
  Settings? s = realm.find<Settings>(0);
  if (s == null) {
    realm.write(() {
      realm.add(Settings(0, presetLimit: 200));
    });
    s = realm.find<Settings>(0);
  }

  return s!;
}
