import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
