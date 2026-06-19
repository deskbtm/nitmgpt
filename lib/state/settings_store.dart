import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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
import 'package:nitmgpt/core/safe_signal_write.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
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

class GithubFetchResult {
  const GithubFetchResult._({
    this.release,
    this.networkError = false,
  });

  const GithubFetchResult.success(GithubRelease release)
      : this._(release: release);

  const GithubFetchResult.notFound() : this._();

  const GithubFetchResult.networkError() : this._(networkError: true);

  final GithubRelease? release;
  final bool networkError;
}

class SettingsStore {
  static const bootAutoStartKvKey = 'nitmgpt_boot_auto_start';

  GithubRelease? githubRelease;
  late Settings settings;

  late final RealmStringSignal proxyUri;
  late final RealmBoolSignal ownedApp;
  late final RealmBoolSignal ignoreSystemApps;
  late final KvBoolSignal bootAutoStart;

  final isVerifyLoading = signal(false);
  final currentVersion = signal<Version?>(null);

  final proxyUriController = TextEditingController();
  final ownAppController = TextEditingController();

  Future<void> init() async {
    settings = getSettingInstance();

    proxyUri =
        realmString(settings, (s) => s.proxyUri, (s, v) => s.proxyUri = v);
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
    bootAutoStart = kvBool(
      bootAutoStartKvKey,
      defaultValue: true,
      asyncWrite: true,
    );

    if (Platform.isAndroid) {
      await applyPermanentListenerAutoStartOnBoot(bootAutoStart.value);
    }

    setAppLocale(localeFromLanguageCode(settings.language));
    proxyUriController.text = proxyUri.value;

    final packageInfo = await PackageInfo.fromPlatform();
    safeSignalWrite(
      () => currentVersion.value = Version.parse(packageInfo.version),
    );
  }

  void dispose() {
    proxyUriController.dispose();
    ownAppController.dispose();
  }

  Future<void> setBootAutoStart(bool enabled) async {
    bootAutoStart.value = enabled;
    if (Platform.isAndroid) {
      await applyPermanentListenerAutoStartOnBoot(enabled);
    }
  }

  Future<GithubFetchResult> _fetchGithubRelease(
      String owner, String repo) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return const GithubFetchResult.notFound();
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final arch = getArch(SysInfo.kernelArchitecture.name);

      if (body['tag_name'] == null || body['assets'] == null) {
        return const GithubFetchResult.notFound();
      }

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
          return GithubFetchResult.success(
            GithubRelease(
              url: assetMap['browser_download_url'] as String,
              version: body['tag_name'] as String,
              size: assetMap['size'] as int,
              changelog: body['body'] as String? ?? '',
              sha256sum: checksum,
            ),
          );
        }
      }

      return const GithubFetchResult.notFound();
    } on SocketException catch (error, stackTrace) {
      log(
        'GitHub release fetch failed: $error',
        name: 'SettingsStore',
        stackTrace: stackTrace,
      );
      return const GithubFetchResult.networkError();
    } on http.ClientException catch (error, stackTrace) {
      log(
        'GitHub release fetch failed: $error',
        name: 'SettingsStore',
        stackTrace: stackTrace,
      );
      return const GithubFetchResult.networkError();
    } on Exception catch (error, stackTrace) {
      log(
        'GitHub release fetch failed: $error',
        name: 'SettingsStore',
        stackTrace: stackTrace,
      );
      return const GithubFetchResult.notFound();
    }
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
    final result = await _fetchGithubRelease('deskbtm', 'nitmgpt');
    if (!context.mounted) return;

    if (result.networkError) {
      Fluttertoast.showToast(
        msg: 'Unable to reach GitHub. Check your network.'.tr,
      );
      return;
    }

    final release = result.release;
    if (release == null) {
      Fluttertoast.showToast(msg: 'Latest version'.tr);
      return;
    }

    githubRelease = release;
    final latest = Version.parse(release.version.replaceFirst('v', ''));
    final current = currentVersion.value;

    if (current != null && latest > current) {
      await _showUpdateDialog(context, latest);
    } else {
      Fluttertoast.showToast(msg: 'Latest version'.tr);
    }
  }

  Future<void> _showUpdateDialog(BuildContext context, Version latest) async {
    await showAppDialog<void>(
      context: context,
      title: 'v${latest.toString()} available!',
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
        AppDialogAction(
          label: 'Update',
          isPrimary: true,
          onPressed: () {
            _downloadArchive();
            popDialog(dialogContext);
          },
        ),
      ],
    );
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

  Future<bool> _accessApp() async {
    try {
      final username = ownAppController.text.trim();
      return (await verifyGithubStarred(username, REPO_NAME) ||
          await verifyGithubFollowed(username, MY_GITHUB_NAME));
    } on SocketException catch (error, stackTrace) {
      log(
        'GitHub verify failed: $error',
        name: 'SettingsStore',
        stackTrace: stackTrace,
      );
      return false;
    } on http.ClientException catch (error, stackTrace) {
      log(
        'GitHub verify failed: $error',
        name: 'SettingsStore',
        stackTrace: stackTrace,
      );
      return false;
    }
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
        safeSignalWrite(() => isVerifyLoading.value = true);
        final verified = await _accessApp();
        safeSignalWrite(() {
          isVerifyLoading.value = false;
          ownedApp.value = verified;
        });
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
