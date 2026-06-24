import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nitmgpt/components/dialog.dart';
import 'package:nitmgpt/core/constants.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/core/idle_scheduler.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/core/safe_signal_write.dart';
import 'package:nitmgpt/services/device_apps.dart';
import 'package:nitmgpt/services/app_icon_loader.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/utils/notification_search.dart';
import 'package:nitmgpt/services/permanent_listener/background_service_host.dart';
import 'package:nitmgpt/app/app_navigator.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signals/signals.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class WatcherStore {
  WatcherStore(this._settingsStore);

  static const _legacyMockPackageNames = [
    'com.nitmgpt.mock.wechat',
    'com.nitmgpt.mock.shopping',
    'com.nitmgpt.mock.news',
  ];

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
  final Set<String> _deletingRecordIds = {};

  late Settings settings;
  int _iconLoadToken = 0;
  StreamSubscription<Map<String, dynamic>?>? _backgroundServiceSub;

  Future<void> init() async {
    settings = _settingsStore.settings;

    await _purgeLegacyMockRecords();
    refreshDetectedApps();

    scheduleIdleStartupTask(_initHeavy);
  }

  Future<void> _initHeavy() async {
    final context = rootNavigatorContext;
    if (context == null) return;

    final hasPermission = await _initPermission(context);

    if (hasPermission) {
      log('Start permanent service android notification listener service');
      await _startPermanentService();
      if (await hasActiveLocalModelForListener()) {
        await startNotificationService();
      }

      deviceApps.value = await getDeviceApps(
        includeAppIcons: false,
        prefetchAllIconsInBackground: false,
      );
      refreshDetectedApps();

      settings = _settingsStore.settings;

      if (settings.ownedApp == null) {
        Timer(const Duration(seconds: 5), () {
          final ctx = rootNavigatorContext;
          if (ctx != null) {
            _settingsStore.verifyOwnedApp(ctx);
          }
        });
      }
    } else {
      deviceApps.value = await getDeviceApps(
        includeAppIcons: false,
        prefetchAllIconsInBackground: false,
      );
      refreshDetectedApps();
    }
    // Deferred full icon catalog prefetch disabled — only on-screen apps load
    // icons via refreshDetectedApps → _loadMissingIconsFor.
    // scheduleIdleStartupTask(
    //   _loadAppIconsInBackground,
    //   delay: const Duration(seconds: 4),
    // );
  }

  Future<void> _purgeLegacyMockRecords() async {
    final mockApps = realm
        .all<RecordedApp>()
        .where((app) => _legacyMockPackageNames.contains(app.packageName))
        .toList();
    if (mockApps.isEmpty) {
      return;
    }

    await realm.writeAsync(() {
      for (final app in mockApps) {
        realm.delete(app);
      }
    });
    _bumpRecordsRevision();
  }

  ApplicationWithIcon? _resolveRecordedApp(RecordedApp recordedApp) {
    final mapped = deviceAppsMap.value[recordedApp.packageName];
    if (mapped != null) return mapped;

    if (recordedApp.records.isEmpty) return null;

    final first = recordedApp.records.first;
    return ApplicationWithIcon(
      appName: first.appName ?? recordedApp.packageName,
      packageName: recordedApp.packageName,
      systemApp: false,
    );
  }

  void dispose() {
    _backgroundServiceSub?.cancel();
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
    await stopPermanentListenerBackgroundService();
    await SystemNavigator.pop();
  }

  Future<void> _startPermanentService() async {
    await configurePermanentListenerBackgroundService(
      autoStartOnBoot: _settingsStore.bootAutoStart.value,
    );
    await syncPermanentListenerBackgroundService();

    _backgroundServiceSub?.cancel();
    _backgroundServiceSub = FlutterBackgroundService()
        .on(BackgroundServiceAction.updateRecords)
        .listen((_) {
      onBackgroundServiceRecordsUpdated();
    });
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
    bool prefetchAllIconsInBackground = true,
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

    deviceAppsMap.value = map;
    deviceApps.value = list;

    if (!includeAppIcons && prefetchAllIconsInBackground) {
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
    if (!await hasActiveLocalModelForListener()) {
      log(
        'Notification listener not started — no active local model',
        name: 'NotificationService',
      );
      Fluttertoast.showToast(msg: 'No active model'.tr);
      isListening.value = false;
      return;
    }

    if (Platform.isAndroid && !await _ensureNotificationPostPermission()) {
      isListening.value = false;
      return;
    }

    await configurePermanentListenerBackgroundService(
      autoStartOnBoot: _settingsStore.bootAutoStart.value,
    );
    await syncPermanentListenerBackgroundService();

    final backgroundRunning = await FlutterBackgroundService().isRunning();
    if (!backgroundRunning) {
      log(
        'Background service failed to stay running',
        name: 'NotificationService',
      );
      Fluttertoast.showToast(msg: 'Failed to start listener service'.tr);
      isListening.value = false;
      return;
    }

    final isRunning = await NotificationsListener.isRunning ?? false;

    if (!isRunning) {
      final isSuccess = await NotificationsListener.startService(
            foreground: false,
            title: 'Listener Running',
          ) ??
          false;
      if (isSuccess) {
        log('Start listening', name: 'NotificationService');
      } else {
        Fluttertoast.showToast(
          msg: 'Notification listener is not running'.tr,
        );
        isListening.value = false;
        return;
      }
    }
    isListening.value = true;
  }

  Future<bool> _ensureNotificationPostPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      return true;
    }

    Fluttertoast.showToast(
      msg:
          'Notification permission is required to keep the listener running'.tr,
    );
    return false;
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

  void _bumpRecordsRevision() {
    safeSignalWrite(() => recordsRevision.value++);
  }

  void _refreshDetectedAppsIfChanged() {
    final nextApps = getDetectedApps();
    final current = detectedApps.value;
    if (current.length != nextApps.length ||
        !_sameAppPackages(current, nextApps)) {
      detectedApps.value = nextApps;
    }
  }

  void _notifyDeleteFailed() {
    Fluttertoast.showToast(msg: 'Failed to delete notification'.tr);
    _bumpRecordsRevision();
  }

  List<Record> getRecords({String? packageName}) {
    _ensureRecordsCacheFresh();

    if (packageName == null) {
      return _allRecordsCache ??= realm
          .all<RecordedApp>()
          .expand((element) => element.records)
          .toList();
    }

    final normalizedPackage = packageName.trim();
    if (normalizedPackage.isEmpty) {
      return const [];
    }

    return _recordsByPackageCache.putIfAbsent(normalizedPackage, () {
      final result = realm.query<RecordedApp>(
        'packageName == \$0',
        [normalizedPackage],
      );
      if (result.isEmpty) {
        return const [];
      }
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
    return deviceAppsMap.value[packageName];
  }

  void refreshDetectedApps() {
    final nextApps = getDetectedApps();
    final current = detectedApps.value;
    if (current.length != nextApps.length ||
        !_sameAppPackages(current, nextApps)) {
      detectedApps.value = nextApps;
    }
    final missingIcons = detectedApps.value
        .map((app) => app.packageName)
        .where((packageName) => !_appHasIcon(packageName));
    if (missingIcons.isNotEmpty) {
      unawaited(_loadMissingIconsFor(missingIcons));
    }
  }

  /// Reloads detected apps and record lists for pull-to-refresh on Home.
  Future<void> refreshHomeRecords() async {
    refreshDetectedApps();
    _bumpRecordsRevision();
  }

  Future<void> deleteRecord(Record record) async {
    if (!_deletingRecordIds.add(record.id.toString())) {
      return;
    }

    try {
      final recordId = record.id;
      final packageName = record.packageName?.trim();
      if (packageName == null || packageName.isEmpty) {
        _notifyDeleteFailed();
        return;
      }

      var removed = false;
      try {
        await realm.writeAsync(() {
          final apps =
              realm.query<RecordedApp>('packageName == \$0', [packageName]);
          if (apps.isEmpty) {
            return;
          }

          final app = apps.first;
          final index =
              app.records.indexWhere((item) => item.id == recordId);
          if (index < 0) {
            return;
          }

          app.records.removeAt(index);
          removed = true;
          if (app.records.isEmpty) {
            realm.delete(app);
          }
        });
      } catch (e, st) {
        log('deleteRecord failed', error: e, stackTrace: st);
        _notifyDeleteFailed();
        return;
      }

      if (!removed) {
        _notifyDeleteFailed();
        return;
      }

      safeSignalWrite(() {
        recordsRevision.value++;
        _refreshDetectedAppsIfChanged();
      });
    } finally {
      _deletingRecordIds.remove(record.id.toString());
    }
  }

  void onBackgroundServiceRecordsUpdated() {
    safeSignalWrite(() {
      _refreshDetectedAppsIfChanged();
      recordsRevision.value++;
    });
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
