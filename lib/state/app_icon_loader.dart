import 'dart:typed_data';

import 'package:installed_apps/installed_apps.dart';
import 'package:nitmgpt/device_apps_compat.dart';

const int kAppIconLoadBatchSize = 6;

/// Returns package names in load order: [priority] first, then the rest.
List<String> orderPackagesForIconLoad({
  required Iterable<String> allPackages,
  required Iterable<String> priorityPackages,
}) {
  final priority = <String>{
    for (final package in priorityPackages)
      if (package.isNotEmpty) package,
  };
  final ordered = <String>[
    for (final package in priority)
      if (allPackages.contains(package)) package,
  ];
  for (final package in allPackages) {
    if (!priority.contains(package)) {
      ordered.add(package);
    }
  }
  return ordered;
}

Future<void> loadAppIconsInBatches({
  required Iterable<String> packageNames,
  required bool Function() isCancelled,
  required bool Function(String packageName) alreadyHasIcon,
  required void Function(Map<String, Uint8List> icons) onBatchLoaded,
  int batchSize = kAppIconLoadBatchSize,
}) async {
  final pending = <String, Uint8List>{};

  for (final packageName in packageNames) {
    if (isCancelled()) return;
    if (alreadyHasIcon(packageName)) continue;

    final info = await InstalledApps.getAppInfo(packageName, null);
    final icon = info?.icon;
    if (icon != null && icon.isNotEmpty) {
      pending[packageName] = icon;
    }

    if (pending.length >= batchSize) {
      onBatchLoaded(Map<String, Uint8List>.from(pending));
      pending.clear();
      await Future<void>.delayed(Duration.zero);
    }
  }

  if (pending.isNotEmpty && !isCancelled()) {
    onBatchLoaded(pending);
  }
}

ApplicationWithIcon copyAppWithIcon(
  ApplicationWithIcon app,
  Uint8List icon,
) {
  return ApplicationWithIcon(
    appName: app.appName,
    packageName: app.packageName,
    systemApp: app.systemApp,
    icon: icon,
  );
}
