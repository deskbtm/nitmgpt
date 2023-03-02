import 'dart:developer';
import 'dart:io';
import 'package:device_apps/device_apps.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/pages/settings/settings_controller.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import '../../constants.dart';
import '../../models/realm.dart';
import '../../permanent_listener_service/main.dart';

class WatcherController extends FullLifeCycleController
    with FullLifeCycleMixin {
  static WatcherController get to => Get.find();

  final records = Rxn<List<Record>>([]);

  final deviceApps = <ApplicationWithIcon>[].obs;

  final deviceAppsMap = RxMap<String, ApplicationWithIcon>({});

  /// This records2 is used for the HomeScreen, it will pop
  /// and push record when out of limit.
  final records2 = <Record>[].obs;

  final isListening = false.obs;

  final _settingController = SettingsController.to;

  static showNB({VoidCallback? onConfirm, required String title}) {
    return Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 20),
      titleStyle: const TextStyle(fontSize: 22),
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

          Get.back();
        },
      ),
    );
  }

  addRecord(Record record) async {
    // records.add(record);
    if (records2.length > 2000) {
      records2.insert(0, record);
      records2.removeLast();
    } else {
      records2.add(record);
    }
  }

  Future<void> clearRecords() async {
    records.value = [];
    realm.write(() {
      realm.deleteAll<Record>();
    });
  }

  _initDeviceApps() async {
    var apps = (await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
    ));

    deviceApps.addAll(apps.map((e) {
      // ignore: invalid_use_of_protected_member
      deviceAppsMap.value[e.packageName] = e as ApplicationWithIcon;

      return e;
    }));
  }

  _startPermanentService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _startService,
        autoStart: true,
        isForegroundMode: true,
        initialNotificationTitle: 'NITMGPT SERVICE',
        initialNotificationContent: 'running...',
      ),
      iosConfiguration: IosConfiguration(),
    );

    service.on('update_records').listen((event) async {
      records.value = realm.all<Record>().toList();
    });

    service.on('set_api_key').listen((event) async {
      await _settingController.setupOpenAiKey();
    });
  }

  @pragma('vm:entry-point')
  static _startService(ServiceInstance service) async {
    await permanentListenerServiceMain(service);
  }

  _permissionDialog() async {
    var hasPermission = await NotificationsListener.hasPermission ?? false;
    bool isBatteryOptimizationDisabled =
        await DisableBatteryOptimization.isBatteryOptimizationDisabled ?? false;

    if (hasPermission) {
      await toggleNotificationService();
    } else {
      await showNB(
          title: 'Notification Listener'.tr,
          onConfirm: () {
            NotificationsListener.openPermissionSettings();
          });
    }
    if (!isBatteryOptimizationDisabled) {
      await showNB(
        title: 'Battery Optimization !'.tr,
        onConfirm: () async {
          await DisableBatteryOptimization
              .showDisableBatteryOptimizationSettings();
        },
      );
    }
  }

  toggleNotificationService() async {
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

  exportXlsx() async {
    var exportRecords = records.value!.reversed.toList();
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

  @override
  void onInit() async {
    super.onInit();

    records.value = realm.all<Record>().toList().reversed.toList();

    await _permissionDialog();
    await _initDeviceApps();
    await _startPermanentService();
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {
    records.value = realm.all<Record>().toList().reversed.toList();
  }
}
