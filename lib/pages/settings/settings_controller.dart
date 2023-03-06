import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/i18n/i18n.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/utils.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nitmgpt/notification_utils.dart';
import 'package:system_info2/system_info2.dart';
import 'package:version/version.dart';

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

  late final GithubRelease? githubRelease;
  final proxyUri = ''.obs;
  final ownedApp = false.obs;
  final openAiKey = ''.obs;
  final _isVerifyLoading = false.obs;
  final currentVersion = Rxn<Version>();
  final latestVersion = Rxn<Version>();
  final proxyUriController = TextEditingController();
  final openAiKeyController = TextEditingController();
  final ownAppController = TextEditingController();

  late Settings settings;

  Future<GithubRelease?> _fetchGithubRelease(String owner, String repo) async {
    var res = await GetConnect()
        .get("https://api.github.com/repos/$owner/$repo/releases/latest");

    GithubRelease? resource;

    if (res.isOk) {
      String arch = getArch(SysInfo.kernelArchitecture.name);
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

  void _downloadArchive() {
    if (githubRelease != null) {
      OtaUpdate()
          .execute(githubRelease!.url, sha256checksum: githubRelease!.sha256sum)
          .listen(
        (OtaEvent event) async {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              if (event.value != null) {
                await LocalNotification.showNotification(
                  channelName: 'Downloading update',
                  title: 'Downloading update...'.tr,
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
              data: githubRelease!.changelog,
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
            _downloadArchive();
            Get.back();
          },
        ),
      );
    } else {
      await _checkGithubLatestRelease();
      if (hasNewVersion()) {
        checkUpdate();
      } else {
        Fluttertoast.showToast(msg: 'Latest version');
      }
    }
  }

  setupProxy() async {
    return showCommonDialog(
      controller: proxyUriController,
      title: "Setup proxy".tr,
      cancelText: "Reset".tr,
      onCancel: () async {
        proxyUri.value = '';
        proxyUriController.text = '';
        realm.write(() {
          settings.proxyUri = null;
        });
      },
      onConfirm: () async {
        proxyUri.value = proxyUriController.text.trim();
        realm.write(() {
          settings.proxyUri = proxyUriController.text.trim();
        });
        Get.back();
      },
    );
  }

  setupOpenAiKey() async {
    var description = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text: "You could get OpenAI API Key from ".tr,
          ),
          TextSpan(
            text: openAiKeysUrl,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await open(openAiKeysUrl);
              },
          ),
        ],
      ),
    );

    return showCommonDialog(
      controller: openAiKeyController,
      title: "Setup OpenAI API Key".tr,
      description: description,
      cancelText: "Reset".tr,
      onCancel: () async {
        openAiKey.value = '';
        openAiKeyController.text = '';
        realm.write(() {
          settings.openAiKey = null;
        });
      },
      onConfirm: () async {
        openAiKey.value = openAiKeyController.text.trim();
        realm.write(() {
          settings.openAiKey = openAiKeyController.text.trim();
        });
        Get.back();
      },
    );
  }

  Future<void> _checkGithubLatestRelease() async {
    GithubRelease? res = await _fetchGithubRelease("deskbtm", "nitmgpt");

    if (res != null) {
      githubRelease = res;
      latestVersion.value = Version.parse(res.version.replaceFirst("v", ''));
    }
  }

  Future<bool> _accessApp() async {
    return (await verifyGithubStarred(
            ownAppController.text.trim(), REPO_NAME) ||
        await verifyGithubFollowed(
            ownAppController.text.trim(), MY_GITHUB_NAME));
  }

  _ignoreGetApp(bool owned) async {
    await realm.writeAsync(() => {settings.ownedApp = owned});
    ownedApp.value = owned;
  }

  verifyOwnedApp() {
    var description = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text:
                "You could follow my Github or star this project to hide this dialog "
                    .tr,
          ),
          TextSpan(
            text: githubRepoUrl,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await open(githubRepoUrl);
              },
          ),
        ],
      ),
    );
    return showCommonDialog(
      title: "Get this App".tr,
      controller: ownAppController,
      description: description,
      textFieldPlaceholder: "Github account name".tr,
      onCancel: () async {
        await _ignoreGetApp(true);
        Get.back();
      },
      onWillPop: () async {
        await _ignoreGetApp(true);
        return true;
      },
      cancelText: 'Ignore forever'.tr,
      suffix: SizedBox(
        width: 20,
        height: 20,
        child: Obx(
          () => _isVerifyLoading.value
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Container(),
        ),
      ),
      onConfirm: () async {
        _isVerifyLoading.value = true;
        _accessApp().then((owned) async {
          _isVerifyLoading.value = false;
          await _ignoreGetApp(owned);
          Get.back();
        });
      },
    );
  }

  void setLanguage() {
    String code = Get.locale!.languageCode;

    if (code.contains('en')) {
      Get.updateLocale(TranslationService.zhCN);
      realm.write(() {
        settings.language = 'zh_CN';
      });
    }

    if (code.contains('zh')) {
      Get.updateLocale(TranslationService.enUS);
      realm.write(() {
        settings.language = 'en_US';
      });
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

    if (settings.ownedApp == true) {
      ownedApp.value = true;
    }

    var packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = Version.parse(packageInfo.version);

    super.onInit();
  }

  @override
  void onReady() async {
    await _checkGithubLatestRelease();

    super.onReady();
  }
}
