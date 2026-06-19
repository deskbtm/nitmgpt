import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';

Settings readBackgroundSettings() {
  var settings = realm.find<Settings>(0);
  if (settings == null) {
    realm.write(() {
      realm.add(Settings(0, presetLimit: 200));
    });
    settings = realm.find<Settings>(0);
  }
  return settings!;
}
