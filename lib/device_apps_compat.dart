import 'dart:typed_data';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class Application {
  final String appName;
  final String packageName;
  final bool systemApp;

  Application({
    required this.appName,
    required this.packageName,
    required this.systemApp,
  });

  factory Application.fromAppInfo(
    AppInfo info, {
    bool systemApp = false,
  }) {
    return Application(
      appName: info.name,
      packageName: info.packageName,
      systemApp: systemApp,
    );
  }
}

class ApplicationWithIcon extends Application {
  final Uint8List? icon;

  ApplicationWithIcon({
    required super.appName,
    required super.packageName,
    required super.systemApp,
    this.icon,
  });

  factory ApplicationWithIcon.fromAppInfo(
    AppInfo info, {
    bool systemApp = false,
  }) {
    return ApplicationWithIcon(
      appName: info.name,
      packageName: info.packageName,
      systemApp: systemApp,
      icon: info.icon,
    );
  }
}

class DeviceApps {
  static Future<List<Application>> getInstalledApplications({
    bool includeAppIcons = false,
    bool includeSystemApps = false,
  }) async {
    final apps = await InstalledApps.getInstalledApps(
      !includeSystemApps,
      includeAppIcons,
    );

    if (!includeSystemApps && !includeAppIcons) {
      return apps.map((info) => Application.fromAppInfo(info)).toList();
    }

    final results = <Application>[];
    for (final info in apps) {
      final systemApp =
          await InstalledApps.isSystemApp(info.packageName) ?? false;

      if (includeAppIcons) {
        results.add(ApplicationWithIcon.fromAppInfo(
          info,
          systemApp: systemApp,
        ));
      } else {
        results.add(Application.fromAppInfo(
          info,
          systemApp: systemApp,
        ));
      }
    }

    return results;
  }
}
