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

/// Loads the full installed-app catalog once (worker isolate only).
///
/// Uses two native queries so [systemApp] is known without per-package calls.
Future<Map<String, ApplicationWithIcon>> loadDeviceAppCatalog() async {
  final userApps = await InstalledApps.getInstalledApps(true, false);
  final allApps = await InstalledApps.getInstalledApps(false, false);
  final userPackages = userApps.map((app) => app.packageName).toSet();

  final catalog = <String, ApplicationWithIcon>{};
  for (final info in allApps) {
    catalog[info.packageName] = ApplicationWithIcon(
      appName: info.name,
      packageName: info.packageName,
      systemApp: !userPackages.contains(info.packageName),
    );
  }
  return catalog;
}

List<Map<String, dynamic>> deviceAppCatalogToMaps(
  Iterable<ApplicationWithIcon> apps,
) {
  return [
    for (final app in apps)
      {
        'packageName': app.packageName,
        'appName': app.appName,
        'systemApp': app.systemApp,
      },
  ];
}

List<ApplicationWithIcon> deviceAppCatalogFromMaps(
  Iterable<dynamic> raw, {
  bool includeSystemApps = false,
}) {
  final apps = <ApplicationWithIcon>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final packageName = entry['packageName'];
    final appName = entry['appName'];
    if (packageName is! String || appName is! String) continue;
    final systemApp = entry['systemApp'] == true;
    if (!includeSystemApps && systemApp) continue;
    apps.add(
      ApplicationWithIcon(
        appName: appName,
        packageName: packageName,
        systemApp: systemApp,
      ),
    );
  }
  apps.sort((a, b) => a.appName.compareTo(b.appName));
  return apps;
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
