import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:nitmgpt/constants.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:nitmgpt/utils.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/pages/settings/settings_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

class WatcherController extends FullLifeCycleController
    with FullLifeCycleMixin {
  static WatcherController get to => Get.find();

  final deviceApps = <ApplicationWithIcon>[].obs;

  final deviceAppsMap = RxMap<String, ApplicationWithIcon>({});

  final isListening = false.obs;

  final _settingController = SettingsController.to;

  final detectedApps = <ApplicationWithIcon>[].obs;

  late final FlutterBackgroundService backgroundService;

  TabController? tabController;

  late Settings settings;

  static showNecessaryPermissionDialog({
    VoidCallback? onConfirm,
    required String title,
    required WillPopCallback onWillPop,
  }) {
    return Get.defaultDialog(
      onWillPop: onWillPop,
      titlePadding: const EdgeInsets.only(top: 20),
      titleStyle: const TextStyle(fontSize: 19),
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      title: title,
      content: Text(
        "Note Bene! This app requires notification listener permission and battery optimization turned off to work."
            .tr,
        style: const TextStyle(fontSize: 16),
      ),
      confirm: TextButton(
        child: const Text(
          "Ok",
          style: TextStyle(fontSize: 20),
        ),
        onPressed: () {
          if (onConfirm != null) {
            onConfirm();
          }
        },
      ),
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
    backgroundService.invoke('stopService');
    await SystemNavigator.pop();
  }

  Future<void> _startPermanentService() async {
    backgroundService = FlutterBackgroundService();

    await backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: permanentListenerServiceMain,
        autoStart: true,
        isForegroundMode: true,
        initialNotificationTitle: 'NITMGPT SERVICE',
        initialNotificationContent: 'running...',
      ),
      iosConfiguration: IosConfiguration(),
    );

    backgroundService.on('prompt_api_key').listen((event) async {
      await _settingController.setupOpenAiKey();
    });
  }

  hasNotificationListenerPermission() async {
    return await NotificationsListener.hasPermission ?? false;
  }

  hasBatteryOptimizationDisabledPermission() async {
    return await DisableBatteryOptimization.isBatteryOptimizationDisabled ??
        false;
  }

  Future<bool> _initPermission() async {
    bool isNotificationListenerEnabled =
        await hasNotificationListenerPermission();
    bool isBatteryOptimizationDisabled =
        await hasBatteryOptimizationDisabledPermission();

    if (isNotificationListenerEnabled && isBatteryOptimizationDisabled) {
      return true;
    }

    if (!isNotificationListenerEnabled) {
      await showNecessaryPermissionDialog(
        title: 'Notification Listener'.tr,
        onWillPop: () async {
          return await hasNotificationListenerPermission();
        },
        onConfirm: () async {
          if (await hasNotificationListenerPermission()) {
            Get.back();
          } else {
            NotificationsListener.openPermissionSettings();
          }
        },
      );
    }

    if (!isBatteryOptimizationDisabled) {
      await showNecessaryPermissionDialog(
        title: 'Battery Optimization !'.tr,
        onWillPop: () async {
          return await hasBatteryOptimizationDisabledPermission();
        },
        onConfirm: () async {
          if (await hasBatteryOptimizationDisabledPermission()) {
            Get.back();
          } else {
            await DisableBatteryOptimization
                .showDisableBatteryOptimizationSettings();
          }
        },
      );
    }

    return true;
  }

  Future<List<ApplicationWithIcon>> getDeviceApps() async {
    var apps = (await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
    ));

    return apps.map((e) {
      deviceAppsMap[e.packageName] = e as ApplicationWithIcon;
      return e;
    }).toList();
  }

  Future<void> startNotificationService() async {
    var isRunning = await NotificationsListener.isRunning ?? false;

    if (!isRunning) {
      bool isSuccess = await NotificationsListener.startService(
            foreground: false,
            title: "Listener Running",
          ) ??
          false;
      if (isSuccess) {
        log('Start listening', name: 'NotificationService');
      }
    }
    isListening.value = true;
  }

  categorize() {}

  Future<void> exportXlsx() async {
    var exportRecords = getRecords();
    int c = 100;
    int n = (exportRecords.length / c).ceil();
    var now = DateTime.now();
    String nowString =
        '${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}_${UniqueKey().toString()}';
    Directory tmp = await getTemporaryDirectory();
    String tmpPath = '${tmp.path}/$nowString';

    List<String> columnNames = [
      "uid",
      "App Name",
      "Package Name",
      "Is Ad",
      "Ad Probability",
      "Is Spam",
      "Spam Probability",
      "Title",
      "Content",
      "Create Time"
    ];

    try {
      if (!Directory(tmpPath).existsSync()) {
        Directory(tmpPath).createSync();
      }

      if (!Directory(documentsDirectory).existsSync()) {
        Directory(documentsDirectory).createSync();
      }

      for (var i = 0; i < n; i++) {
        final Workbook workbook = Workbook();
        final Worksheet sheet = workbook.worksheets[0];
        sheet.showGridlines = true;
        sheet.enableSheetCalculations();
        var e = (i + 1) * c;
        var start = i * c,
            end = exportRecords.length < e ? (exportRecords.length % c) : e;
        var recordList = exportRecords.getRange(start, end);

        for (var k = 0; k < columnNames.length; k++) {
          final Range range =
              sheet.getRangeByName('${String.fromCharCode(65 + k)}1');
          range.setText(columnNames[k]);
          range.autoFit();
        }

        for (var r = 0; r < recordList.length; r++) {
          Record record = recordList.elementAt(r);

          for (var j = 0; j < columnNames.length; j++) {
            final Range range =
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
                    record.isAd != null || record.isAd! ? "Yes" : "No");
                break;
              case 4:
                range.setNumber(record.adProbability);
                break;
              case 5:
                range.setText(
                    record.isAd != null || record.isAd! ? "Yes" : "No");
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
              default:
            }
            range.autoFit();
          }
        }

        final List<int> bytes = workbook.saveAsStream();
        File("$tmpPath/$start~$end.xlsx").writeAsBytes(bytes);
        workbook.dispose();
      }

      await ZipFile.createFromDirectory(
          sourceDir: Directory(tmpPath),
          zipFile: File('$documentsDirectory/$nowString.zip'),
          recurseSubDirs: true);
      Fluttertoast.showToast(msg: 'Save to the $documentsDirectory');
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  List<ApplicationWithIcon> getDetectedApps() {
    var result = realm.all<RecordedApp>();
    List<ApplicationWithIcon> apps = [];

    for (var app in result) {
      if (deviceAppsMap[app.packageName] != null) {
        apps.add(deviceAppsMap[app.packageName]!);
      }
    }

    return apps;
  }

  List<Record> getRecords({String? packageName}) {
    if (packageName == null) {
      return realm
          .all<RecordedApp>()
          .expand((element) => element.records)
          .toList();
    } else {
      var result =
          realm.query<RecordedApp>('packageName == \$0', [packageName]);

      return result.first.records.toList();
    }
  }

  @override
  void onInit() async {
    super.onInit();

    bool hasPermission = await _initPermission();

    if (hasPermission) {
      log('Start permanent service android notification listener service');

      await _startPermanentService();
      await startNotificationService();

      settings = getSettingInstance();

      if (settings.ownedApp == null) {
        Timer(const Duration(seconds: 5), () {
          _settingController.verifyOwnedApp();
        });
      }
    }

    deviceApps.value = await getDeviceApps();
  }

  @override
  void onClose() {
    super.onClose();
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {}
}
