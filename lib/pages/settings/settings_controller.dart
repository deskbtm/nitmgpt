import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/utils.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nitmgpt/notification_utils.dart';
import 'package:system_info2/system_info2.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../../constants.dart';
import '../../i18n/i18n.dart';

class GithubRelease {
  final String version;
  final String url;
  final int size;
  final String changelog;
  final String sha256sum;

  GithubRelease({
    required this.size,
    required this.url,
    required this.version,
    required this.changelog,
    required this.sha256sum,
  });
}

class SettingsController extends GetxController {
  static SettingsController get to => Get.find();

  late final PackageInfo? packageInfo;
  late final release = Rxn<GithubRelease>();
  final proxyUri = ''.obs;
  final openAiKey = ''.obs;
  final currentVersion = Rxn<Version>();
  final latestVersion = Rxn<Version>();
  final proxyUriController = TextEditingController();
  final openAiKeyController = TextEditingController();

  late Settings settings;

  _getArch(String name) {
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

  Future<GithubRelease?> fetchGithubRelease(String owner, String repo) async {
    var res = await GetConnect()
        .get("https://api.github.com/repos/$owner/$repo/releases/latest");

    GithubRelease? resource;

    if (res.isOk) {
      String arch = _getArch(SysInfo.kernelArchitecture.name);
      Map body = res.body;

      if (body["tag_name"] != null && body["assets"] != null) {
        for (Map<dynamic, dynamic> asset in body["assets"]) {
          String filename = "nitmgpt-release-${body["tag_name"]}-$arch";
          if (asset["content_type"] ==
                  "application/vnd.android.package-archive" &&
              asset["name"] == "$filename.apk") {
            late String checksum;
            for (var as in body["assets"]) {
              String n = as["name"];
              if (n.contains(filename) && n.contains("sha256")) {
                checksum = n.split("_").first;
              }
            }
            resource = GithubRelease(
              url: asset["browser_download_url"],
              version: body["tag_name"],
              size: asset["size"],
              changelog: body["body"],
              sha256sum: checksum,
            );
          }
        }
      }
    }

    return resource;
  }

  bool hasNewVersion() {
    if (latestVersion.value != null &&
        currentVersion.value != null &&
        latestVersion.value! > currentVersion.value!) {
      return true;
    }
    return false;
  }

  downloadArchive() {
    OtaUpdate()
        .execute(release.value!.url, sha256checksum: release.value!.sha256sum)
        .listen(
      (OtaEvent event) async {
        switch (event.status) {
          case OtaStatus.DOWNLOADING:
            if (event.value != null) {
              await LocalNotification.showNotification(
                channelName: 'Downloading update',
                title: 'Downloading update',
                onlyAlertOnce: true,
                index: 0,
                progress: int.parse(event.value!),
                maxProgress: 100,
              );
            }
            break;
          default:
        }
      },
    );
  }

  Future<void> checkUpdate() async {
    if (hasNewVersion()) {
      Get.defaultDialog(
        titlePadding: const EdgeInsets.only(top: 20),
        titleStyle: const TextStyle(fontSize: 22),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        title: "v${latestVersion.string} available!",
        content: LimitedBox(
          maxHeight: Get.height / 5,
          child: SizedBox(
            width: double.maxFinite,
            height: double.maxFinite,
            child: Markdown(
              selectable: true,
              data: release.value!.changelog,
              extensionSet: md.ExtensionSet(
                md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                [
                  md.EmojiSyntax(),
                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                ],
              ),
            ),
          ),
        ),
        confirm: TextButton(
          child: const Text(
            "Update",
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            downloadArchive();
            Get.back();
          },
        ),
      );
    } else {
      await initGithubRelease();
      if (hasNewVersion()) {
        checkUpdate();
      } else {
        Fluttertoast.showToast(msg: 'Latest version');
      }
    }
  }

  setupProxy() async {
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      titleStyle: const TextStyle(fontSize: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      title: "Setup proxy",
      content: FractionallySizedBox(
        widthFactor: 0.8,
        child: TextField(
          controller: proxyUriController,
        ),
      ),
      cancel: TextButton(
        child: const Text("Reset", style: TextStyle(fontSize: 20)),
        onPressed: () {
          proxyUri.value = '';
          proxyUriController.text = '';
          realm.write(() {
            settings.proxyUri = null;
          });
        },
      ),
      confirm: TextButton(
        child: const Text("Ok", style: TextStyle(fontSize: 20)),
        onPressed: () {
          proxyUri.value = proxyUriController.text;
          realm.write(() {
            settings.proxyUri = proxyUriController.text;
          });
          Get.back();
        },
      ),
    );
  }

  setupOpenAiKey() async {
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      titleStyle: const TextStyle(fontSize: 22),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      title: "Setup openai api key",
      content: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                const TextSpan(
                  text: "You could get open ai keys from ",
                ),
                TextSpan(
                  text: openAiKeysUrl,
                  style: const TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      Uri uri = Uri.parse(openAiKeysUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                ),
              ],
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.8,
            child: TextField(
              controller: openAiKeyController,
            ),
          ),
        ],
      ),
      cancel: TextButton(
        child: const Text(
          "Reset",
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () {
          openAiKey.value = '';
          openAiKeyController.text = '';
          realm.write(() {
            settings.openAiKey = null;
          });
        },
      ),
      confirm: TextButton(
        child: const Text(
          "Ok",
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () {
          openAiKey.value = openAiKeyController.text;
          realm.write(() {
            settings.openAiKey = openAiKeyController.text;
          });
          Get.back();
        },
      ),
    );
  }

  initGithubRelease() async {
    GithubRelease? res = await fetchGithubRelease("deskbtm", "nitmgpt");

    if (res != null) {
      release.value = res;
      latestVersion.value = Version.parse(res.version.replaceFirst("v", ''));
    }
  }

  setLanguage() {
    String code = Get.locale!.languageCode;

    if (code.contains('en')) {
      Get.updateLocale(TranslationService.zhCN);
    }

    if (code.contains('zh')) {
      Get.updateLocale(TranslationService.enUS);
    }
  }

  @override
  void onInit() async {
    settings = getSettingInstance();

    if (settings.proxyUri != null) {
      proxyUri.value = proxyUriController.text = settings.proxyUri!;
    }

    if (settings.openAiKey != null) {
      openAiKey.value = openAiKeyController.text = settings.openAiKey!;
    }

    packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = Version.parse(packageInfo?.version ?? '');

    super.onInit();
  }

  @override
  void onReady() async {
    await initGithubRelease();
    super.onReady();
  }
}
