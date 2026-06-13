import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
      realm.add(Settings(0, presetLimit: 200));
    });
    s = realm.find<Settings>(0);
  }

  // /// Compat alpha version.
  // realm.write(() {
  //   if (s?.presetLimit == 0) {
  //     s!.presetLimit = 200;
  //   }

  //   if (s?.ignoreSystemApps == null) {
  //     s!.ignoreSystemApps = true;
  //   }
  // });

  return s!;
}

Future<bool> verifyGithubStarred(String username, String repoFullName) async {
  final res = await http.get(
    Uri.parse('https://api.github.com/users/$username/starred'),
  );

  if (res.statusCode == 200) {
    List body = jsonDecode(res.body);
    for (Map<dynamic, dynamic> item in body) {
      if (item['full_name'] == repoFullName) {
        return true;
      }
    }
  } else {
    Fluttertoast.showToast(msg: "Verify request error.");
  }
  return false;
}

Future<bool> verifyGithubFollowed(String username, String target) async {
  final res = await http.get(
    Uri.parse('https://api.github.com/users/$username/following/$target'),
  );

  return res.statusCode == 204;
}

Future<void> open(String url) async {
  Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String getArch(String name) {
  switch (name) {
    case 'X86_64':
      return 'x86_64';
    case 'ARM64':
      return 'arm64-v8a';
    case 'ARM':
      return 'armeabi-v7a';
    default:
      return '';
  }
}
