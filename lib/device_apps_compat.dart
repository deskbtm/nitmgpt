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
  static Future<bool> isSystemApp(String packageName) async {
    return await InstalledApps.isSystemApp(packageName) ?? false;
  }

  static Future<List<ApplicationWithIcon>> getInstalledApplications({
    bool includeAppIcons = false,
    bool includeSystemApps = false,
  }) async {
    final apps = await InstalledApps.getInstalledApps(
      !includeSystemApps,
      includeAppIcons,
    );

    // Native side already filters system apps when [includeSystemApps] is false.
    // Per-app [isSystemApp] calls are deferred; use [DeviceApps.isSystemApp] when needed.
    const systemApp = false;

    return apps
        .map(
          (info) => ApplicationWithIcon.fromAppInfo(
            info,
            systemApp: systemApp,
          ),
        )
        .toList();
  }
}
