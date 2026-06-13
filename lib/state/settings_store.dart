import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/core/realm_signal.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/notification_utils.dart';
import 'package:nitmgpt/utils.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:signals_flutter/signals_flutter.dart';
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

class SettingsStore {
  GithubRelease? githubRelease;
  late Settings settings;

  late final RealmStringSignal proxyUri;
  late final RealmStringSignal openAiKey;
  late final RealmBoolSignal ownedApp;
  late final RealmBoolSignal ignoreSystemApps;

  final isVerifyLoading = signal(false);
  final currentVersion = signal<Version?>(null);
  final latestVersion = signal<Version?>(null);

  final proxyUriController = TextEditingController();
  final openAiKeyController = TextEditingController();
  final ownAppController = TextEditingController();

  Future<void> init() async {
    settings = getSettingInstance();

    proxyUri =
        realmString(settings, (s) => s.proxyUri, (s, v) => s.proxyUri = v);
    openAiKey =
        realmString(settings, (s) => s.openAiKey, (s, v) => s.openAiKey = v);
    ownedApp = realmBool(
      settings,
      (s) => s.ownedApp ?? false,
      (s, v) => s.ownedApp = v,
      asyncWrite: true,
    );
    ignoreSystemApps = realmBool(
      settings,
      (s) => s.ignoreSystemApps,
      (s, v) => s.ignoreSystemApps = v,
      asyncWrite: true,
    );

    appLocale.value = localeFromLanguageCode(settings.language);
    proxyUriController.text = proxyUri.value;
    openAiKeyController.text = openAiKey.value;

    final packageInfo = await PackageInfo.fromPlatform();
    currentVersion.value = Version.parse(packageInfo.version);

    await _checkGithubLatestRelease();
  }

  void dispose() {
    proxyUriController.dispose();
    openAiKeyController.dispose();
    ownAppController.dispose();
  }

  bool hasNewVersion() {
    final latest = latestVersion.value;
    final current = currentVersion.value;
    if (latest != null && current != null && latest > current) {
      return true;
    }
    return false;
  }

  Future<GithubRelease?> _fetchGithubRelease(String owner, String repo) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest'),
    );

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final arch = getArch(SysInfo.kernelArchitecture.name);

    if (body['tag_name'] == null || body['assets'] == null) return null;

    for (final asset in body['assets'] as List<dynamic>) {
      final assetMap = asset as Map<String, dynamic>;
      final filename = 'nitmgpt-release-${body['tag_name']}-$arch';
      if (assetMap['content_type'] ==
              'application/vnd.android.package-archive' &&
          assetMap['name'] == '$filename.apk') {
        String checksum = '';
        for (final as in body['assets'] as List<dynamic>) {
          final n = as['name'] as String;
          if (n.contains(filename) && n.contains('sha256')) {
            checksum = n.split('_').first;
          }
        }
        return GithubRelease(
          url: assetMap['browser_download_url'] as String,
          version: body['tag_name'] as String,
          size: assetMap['size'] as int,
          changelog: body['body'] as String? ?? '',
          sha256sum: checksum,
        );
      }
    }

    return null;
  }

  void _downloadArchive() {
    if (githubRelease == null) return;

    OtaUpdate()
        .execute(
      githubRelease!.url,
      sha256checksum: githubRelease!.sha256sum,
    )
        .listen((OtaEvent event) async {
      if (event.status == OtaStatus.DOWNLOADING && event.value != null) {
        await LocalNotification.showNotification(
          channelName: 'Downloading update',
          title: 'Downloading update...'.tr,
          onlyAlertOnce: true,
          index: 0,
          progress: int.parse(event.value!),
          maxProgress: 100,
        );
      }
    });
  }

  Future<void> checkUpdate(BuildContext context) async {
    if (hasNewVersion()) {
      await showAppDialog<void>(
        context: context,
        title: 'v${latestVersion.value!.toString()} available!',
        content: Builder(
          builder: (dialogContext) {
            return LimitedBox(
              maxHeight: MediaQuery.sizeOf(dialogContext).height / 5,
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
            );
          },
        ),
        actionsBuilder: (dialogContext) => [
          FilledButton(
            onPressed: () {
              _downloadArchive();
              popDialog(dialogContext);
            },
            child: const Text('Update'),
          ),
        ],
      );
    } else {
      await _checkGithubLatestRelease();
      if (!context.mounted) return;
      if (hasNewVersion()) {
        await checkUpdate(context);
      } else {
        Fluttertoast.showToast(msg: 'Latest version');
      }
    }
  }

  Future<void> setupProxy(BuildContext context) {
    return showAppInputDialog(
      context: context,
      controller: proxyUriController,
      title: 'Setup proxy'.tr,
      cancelText: 'Reset'.tr,
      onCancel: (dialogContext) async {
        proxyUri.value = '';
        proxyUriController.text = '';
      },
      onConfirm: (dialogContext) async {
        proxyUri.value = proxyUriController.text.trim();
        popDialog(dialogContext);
      },
    );
  }

  Future<void> setupOpenAiKey(BuildContext context) {
    final description = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(text: 'You could get OpenAI API Key from '.tr),
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

    return showAppInputDialog(
      context: context,
      controller: openAiKeyController,
      title: 'Setup OpenAI API Key'.tr,
      description: description,
      cancelText: 'Reset'.tr,
      onCancel: (dialogContext) async {
        openAiKey.value = '';
        openAiKeyController.text = '';
      },
      onConfirm: (dialogContext) async {
        openAiKey.value = openAiKeyController.text.trim();
        popDialog(dialogContext);
      },
    );
  }

  Future<void> _checkGithubLatestRelease() async {
    final res = await _fetchGithubRelease('deskbtm', 'nitmgpt');
    if (res != null) {
      githubRelease = res;
      latestVersion.value = Version.parse(res.version.replaceFirst('v', ''));
    }
  }

  Future<bool> _accessApp() async {
    final username = ownAppController.text.trim();
    return (await verifyGithubStarred(username, REPO_NAME) ||
        await verifyGithubFollowed(username, MY_GITHUB_NAME));
  }

  Future<void> verifyOwnedApp(BuildContext context) {
    final description = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: [
          TextSpan(
            text:
                'You could follow my Github or star this project to hide this dialog '
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

    return showAppInputDialog(
      context: context,
      title: 'Get this App'.tr,
      controller: ownAppController,
      description: description,
      hint: 'Github account name'.tr,
      onCancel: (dialogContext) async {
        ownedApp.value = true;
        popDialog(dialogContext);
      },
      cancelText: 'Ignore forever'.tr,
      suffix: SignalBuilder(
        builder: (context) => SizedBox(
          width: 20,
          height: 20,
          child: isVerifyLoading.value
              ? const CircularProgressIndicator(strokeWidth: 2)
              : const SizedBox.shrink(),
        ),
      ),
      onConfirm: (dialogContext) async {
        isVerifyLoading.value = true;
        final verified = await _accessApp();
        isVerifyLoading.value = false;
        ownedApp.value = verified;
        popDialog(dialogContext);
      },
    );
  }

  void setLanguage() {
    final code = appLocale.value.languageCode;

    if (code.contains('en')) {
      setAppLocale(const Locale('zh', 'CN'));
      realm.write(() {
        settings.language = 'zh_CN';
      });
    } else if (code.contains('zh')) {
      setAppLocale(const Locale('en', 'US'));
      realm.write(() {
        settings.language = 'en_US';
      });
    }
  }
}
