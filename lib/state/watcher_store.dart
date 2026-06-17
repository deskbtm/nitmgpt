import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/device_apps_compat.dart';
import 'package:nitmgpt/state/app_icon_loader.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/mock/home_mock_data.dart';
import 'package:nitmgpt/state/notification_search_helpers.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:nitmgpt/app/app_navigator.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class WatcherStore {
  WatcherStore(this._settingsStore);

  final SettingsStore _settingsStore;

  final deviceApps = signal<List<ApplicationWithIcon>>([]);
  final deviceAppsMap = signal<Map<String, ApplicationWithIcon>>({});
  final isListening = signal(false);
  final detectedApps = signal<List<ApplicationWithIcon>>([]);
  final notificationSearchQuery = signal('');
  final recordsRevision = signal(0);

  int _recordsCacheRevision = -1;
  List<Record>? _allRecordsCache;
  final Map<String, List<Record>> _recordsByPackageCache = {};
  String? _searchCacheQuery;
  List<Record>? _searchResultsCache;

  late Settings settings;
  int _iconLoadToken = 0;

  Future<void> init() async {
    final context = rootNavigatorContext;
    if (context == null) return;

    settings = _settingsStore.settings;

    final hasPermission = await _initPermission(context);

    if (hasPermission) {
      log('Start permanent service android notification listener service');
      await _startPermanentService();
      await startNotificationService();

      settings = _settingsStore.settings;

      if (settings.ownedApp == null) {
        Timer(const Duration(seconds: 5), () {
          final ctx = rootNavigatorContext;
          if (ctx != null) {
            _settingsStore.verifyOwnedApp(ctx);
          }
        });
      }
    }

    deviceApps.value = await getDeviceApps(includeAppIcons: false);
    await seedHomeMockDataIfEmpty();
    refreshDetectedApps();
  }

  Future<void> seedHomeMockDataIfEmpty() async {
    final seeded = await HomeMockData.seedIfEmpty(
      registerApp: _registerDeviceApp,
    );
    _ensureMockAppsRegistered();
    if (seeded) {
      recordsRevision.value++;
    }
  }

  void _registerDeviceApp(ApplicationWithIcon app) {
    final map = Map<String, ApplicationWithIcon>.from(deviceAppsMap.value);
    map[app.packageName] = app;
    deviceAppsMap.value = map;
  }

  void _ensureMockAppsRegistered() {
    final map = Map<String, ApplicationWithIcon>.from(deviceAppsMap.value);
    HomeMockData.mergeMockAppsInto(map);
    deviceAppsMap.value = map;
  }

  ApplicationWithIcon? _resolveRecordedApp(RecordedApp recordedApp) {
    final mapped = deviceAppsMap.value[recordedApp.packageName];
    if (mapped != null) return mapped;

    if (recordedApp.records.isEmpty) return null;

    final first = recordedApp.records.first;
    if (HomeMockData.isMockPackage(recordedApp.packageName)) {
      return HomeMockData.applicationFor(recordedApp.packageName);
    }

    return ApplicationWithIcon(
      appName: first.appName ?? recordedApp.packageName,
      packageName: recordedApp.packageName,
      systemApp: false,
    );
  }

  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
  }

  static Future<void> showNecessaryPermissionDialog({
    required BuildContext context,
    Future<void> Function(BuildContext dialogContext)? onConfirm,
    required String title,
    required Future<bool> Function() canDismiss,
  }) {
    return showAppPermissionDialog<void>(
      context: context,
      title: title,
      message:
          'Note Bene! This app requires notification listener permission and battery optimization turned off to work.'
              .tr,
      canDismiss: canDismiss,
      onConfirm: (dialogContext) async {
        if (onConfirm != null) {
          await onConfirm(dialogContext);
        }
      },
    );
  }

  Future<void> clearRecords() async {
    detectedApps.value = [];
    await realm.writeAsync(() {
      realm.deleteAll<RecordedApp>();
      realm.deleteAll<Record>();
    });
    Fluttertoast.showToast(msg: 'Cleanup completed'.tr);
  }

  Future<void> exitAllServices() async {
    await stopPermanentListenerForegroundTask();
    await SystemNavigator.pop();
  }

  void _onForegroundTaskData(Object data) {
    if (data is Map && data['action'] == ForegroundTaskAction.updateRecords) {
      onForegroundTaskRecordsUpdated();
    }
  }

  Future<void> _startPermanentService() async {
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
    await startPermanentListenerForegroundTask();
  }

  Future<bool> hasNotificationListenerPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  Future<bool> hasBatteryOptimizationDisabledPermission() async {
    return await DisableBatteryOptimization.isBatteryOptimizationDisabled ??
        false;
  }

  Future<bool> _initPermission(BuildContext context) async {
    final isNotificationListenerEnabled =
        await hasNotificationListenerPermission();
    final isBatteryOptimizationDisabled =
        await hasBatteryOptimizationDisabledPermission();

    if (isNotificationListenerEnabled && isBatteryOptimizationDisabled) {
      return true;
    }

    if (!isNotificationListenerEnabled) {
      await showNecessaryPermissionDialog(
        context: context,
        title: 'Notification Listener'.tr,
        canDismiss: hasNotificationListenerPermission,
        onConfirm: (dialogContext) async {
          if (await hasNotificationListenerPermission()) {
            popDialog(dialogContext);
          } else {
            NotificationsListener.openPermissionSettings();
          }
        },
      );
    }

    if (!context.mounted) return true;

    if (!isBatteryOptimizationDisabled) {
      await showNecessaryPermissionDialog(
        context: context,
        title: 'Battery Optimization !'.tr,
        canDismiss: hasBatteryOptimizationDisabledPermission,
        onConfirm: (dialogContext) async {
          if (await hasBatteryOptimizationDisabledPermission()) {
            popDialog(dialogContext);
          } else {
            await DisableBatteryOptimization
                .showDisableBatteryOptimizationSettings();
          }
        },
      );
    }

    return true;
  }

  Future<List<ApplicationWithIcon>> getDeviceApps({
    bool includeAppIcons = false,
  }) async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: includeAppIcons,
    );

    final map = <String, ApplicationWithIcon>{};
    final list = <ApplicationWithIcon>[];
    for (final app in apps) {
      map[app.packageName] = app;
      list.add(app);
    }

    HomeMockData.mergeMockAppsInto(map);
    deviceAppsMap.value = map;
    deviceApps.value = list;

    if (!includeAppIcons) {
      unawaited(_loadAppIconsInBackground());
    }

    return list;
  }

  Iterable<String> _iconPriorityPackages() {
    final packages = <String>{
      for (final app in detectedApps.value) app.packageName,
      for (final package in settings.ignoredApps) package,
    };
    return packages;
  }

  bool _appHasIcon(String packageName) {
    final icon = deviceAppsMap.value[packageName]?.icon;
    return icon != null && icon.isNotEmpty;
  }

  void _applyIconPatches(Map<String, Uint8List> icons) {
    if (icons.isEmpty) return;

    final map = Map<String, ApplicationWithIcon>.from(deviceAppsMap.value);
    var list = List<ApplicationWithIcon>.from(deviceApps.value);
    var mapChanged = false;
    var listChanged = false;

    icons.forEach((packageName, icon) {
      final existing = map[packageName];
      if (existing == null) return;
      final updated = copyAppWithIcon(existing, icon);
      map[packageName] = updated;
      mapChanged = true;

      final index = list.indexWhere((app) => app.packageName == packageName);
      if (index >= 0) {
        list[index] = updated;
        listChanged = true;
      }
    });

    if (mapChanged) {
      deviceAppsMap.value = map;
    }
    if (listChanged) {
      deviceApps.value = list;
    }

    final detected = detectedApps.value;
    if (detected.isNotEmpty &&
        detected.any((app) => icons.containsKey(app.packageName))) {
      detectedApps.value = [
        for (final app in detected)
          icons[app.packageName] != null
              ? copyAppWithIcon(app, icons[app.packageName]!)
              : app,
      ];
    }
  }

  Future<void> _loadMissingIconsFor(Iterable<String> packageNames) async {
    await loadAppIconsInBatches(
      packageNames: packageNames,
      isCancelled: () => false,
      alreadyHasIcon: _appHasIcon,
      onBatchLoaded: _applyIconPatches,
    );
  }

  Future<void> _loadAppIconsInBackground() async {
    final token = ++_iconLoadToken;
    final packages = orderPackagesForIconLoad(
      allPackages: deviceAppsMap.value.keys,
      priorityPackages: _iconPriorityPackages(),
    );

    await loadAppIconsInBatches(
      packageNames: packages,
      isCancelled: () => token != _iconLoadToken,
      alreadyHasIcon: _appHasIcon,
      onBatchLoaded: _applyIconPatches,
    );
  }

  Future<void> startNotificationService() async {
    final isRunning = await NotificationsListener.isRunning ?? false;

    if (!isRunning) {
      final isSuccess = await NotificationsListener.startService(
            foreground: false,
            title: 'Listener Running',
          ) ??
          false;
      if (isSuccess) {
        log('Start listening', name: 'NotificationService');
      }
    }
    isListening.value = true;
  }

  Future<void> exportXlsx() async {
    final exportRecords = getRecords();
    const c = 100;
    final n = (exportRecords.length / c).ceil();
    final now = DateTime.now();
    final nowString =
        '${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}_${UniqueKey().toString()}';
    final tmp = await getTemporaryDirectory();
    final tmpPath = '${tmp.path}/$nowString';

    final columnNames = [
      'uid',
      'App Name',
      'Package Name',
      'Is Ad',
      'Ad Probability',
      'Is Spam',
      'Spam Probability',
      'Title',
      'Content',
      'Create Time',
    ];

    try {
      if (!Directory(tmpPath).existsSync()) {
        Directory(tmpPath).createSync();
      }

      if (!Directory(documentsDirectory).existsSync()) {
        Directory(documentsDirectory).createSync();
      }

      for (var i = 0; i < n; i++) {
        final workbook = Workbook();
        final sheet = workbook.worksheets[0];
        sheet.showGridlines = true;
        sheet.enableSheetCalculations();
        final e = (i + 1) * c;
        final start = i * c;
        final end = exportRecords.length < e ? (exportRecords.length % c) : e;
        final recordList = exportRecords.getRange(start, end);

        for (var k = 0; k < columnNames.length; k++) {
          final range = sheet.getRangeByName('${String.fromCharCode(65 + k)}1');
          range.setText(columnNames[k]);
          range.autoFit();
        }

        for (var r = 0; r < recordList.length; r++) {
          final record = recordList.elementAt(r);

          for (var j = 0; j < columnNames.length; j++) {
            final range =
                sheet.getRangeByName('${String.fromCharCode(65 + j)}${2 + r}');
            switch (j) {
              case 0:
                range.setText(record.uid);
                break;
              case 1:
                range.setText(record.appName);
                break;
              case 2:
                range.setText(record.packageName);
                break;
              case 3:
                range.setText(
                    record.isAd != null && record.isAd! ? 'Yes' : 'No');
                break;
              case 4:
                range.setNumber(record.adProbability);
                break;
              case 5:
                range.setText(
                    record.isSpam != null && record.isSpam! ? 'Yes' : 'No');
                break;
              case 6:
                range.setNumber(record.spamProbability);
                break;
              case 7:
                range.setText(record.notificationTitle);
                break;
              case 8:
                range.setText(record.notificationText);
                break;
              case 9:
                range.setDateTime(record.createTime);
                break;
            }
            range.autoFit();
          }
        }

        final bytes = workbook.saveAsStream();
        File('$tmpPath/$start~$end.xlsx').writeAsBytes(bytes);
        workbook.dispose();
      }

      await ZipFile.createFromDirectory(
        sourceDir: Directory(tmpPath),
        zipFile: File('$documentsDirectory/$nowString.zip'),
        recurseSubDirs: true,
      );
      Fluttertoast.showToast(msg: 'Save to the $documentsDirectory');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  List<ApplicationWithIcon> getDetectedApps() {
    _ensureMockAppsRegistered();
    final result = realm.all<RecordedApp>();
    final apps = <ApplicationWithIcon>[];

    for (final app in result) {
      final deviceApp = _resolveRecordedApp(app);
      if (deviceApp != null) {
        apps.add(deviceApp);
      }
    }

    return apps;
  }

  void _ensureRecordsCacheFresh() {
    final revision = recordsRevision.value;
    if (_recordsCacheRevision == revision) {
      return;
    }
    _recordsCacheRevision = revision;
    _allRecordsCache = null;
    _recordsByPackageCache.clear();
    _searchResultsCache = null;
    _searchCacheQuery = null;
  }

  List<Record> getRecords({String? packageName}) {
    _ensureRecordsCacheFresh();

    if (packageName == null) {
      return _allRecordsCache ??= realm
          .all<RecordedApp>()
          .expand((element) => element.records)
          .toList();
    }

    return _recordsByPackageCache.putIfAbsent(packageName, () {
      final result =
          realm.query<RecordedApp>('packageName == \$0', [packageName]);
      return result.first.records.toList();
    });
  }

  List<Record> getRecordsMatchingSearch(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return [];
    }

    _ensureRecordsCacheFresh();

    if (_searchResultsCache != null && _searchCacheQuery == normalized) {
      return _searchResultsCache!;
    }

    final matches = getRecords()
        .where((record) => notificationMatchesSearch(record, normalized))
        .toList();
    matches.sort((a, b) {
      final aTime = a.createTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    _searchCacheQuery = normalized;
    _searchResultsCache = matches;
    return matches;
  }

  ApplicationWithIcon? appIconForPackage(String? packageName) {
    if (packageName == null) return null;
    final mapped = deviceAppsMap.value[packageName];
    if (mapped != null) return mapped;
    if (HomeMockData.isMockPackage(packageName)) {
      return HomeMockData.applicationFor(packageName);
    }
    return null;
  }

  void refreshDetectedApps() {
    detectedApps.value = getDetectedApps();
    final missingIcons = detectedApps.value
        .map((app) => app.packageName)
        .where((packageName) => !_appHasIcon(packageName));
    if (missingIcons.isNotEmpty) {
      unawaited(_loadMissingIconsFor(missingIcons));
    }
  }

  void onForegroundTaskRecordsUpdated() {
    final nextApps = getDetectedApps();
    final current = detectedApps.value;
    if (current.length != nextApps.length ||
        !_sameAppPackages(current, nextApps)) {
      detectedApps.value = nextApps;
    }
    recordsRevision.value++;
  }

  bool _sameAppPackages(
    List<ApplicationWithIcon> a,
    List<ApplicationWithIcon> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].packageName != b[i].packageName) return false;
    }
    return true;
  }
}
