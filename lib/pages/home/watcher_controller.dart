import 'dart:developer';
import 'dart:ui';
import 'package:device_apps/device_apps.dart';
import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/models/record.dart';
import '../../models/realm.dart';
import '../../permanent_listener_service/main.dart';

class WatcherController extends GetxController {
  static WatcherController get to => Get.find();
  // final records = <Record>[].obs;
  final records = Rxn<List<Record>>([]);
  // late Box<Record> recordsBox;
  final deviceApps = <ApplicationWithIcon>[].obs;

  /// This records2 is used for the HomeScreen, it will pop
  /// and push record when out of limit.
  final records2 = <Record>[].obs;
  final isListening = false.obs;

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

  initDeviceApps() async {
    var apps = (await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
    ));

    deviceApps.addAll(apps.map((e) => e as ApplicationWithIcon));
  }

  @override
  void onInit() async {
    super.onInit();

    records.value = realm.all<Record>().toList();

    await _permissionDialog();
    await initDeviceApps();
    await _startPermanentService();
  }

  _startPermanentService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStartService,
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
  }

  @pragma('vm:entry-point')
  static onStartService(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

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
    // var exportRecords = records.reversed.toList();
    // int c = 100;
    // int n = (records.length / c).ceil();
    // var now = DateTime.now();
    // String nowString =
    //     '${now.year}-${now.month}-${now.day}_${now.hour}-${now.minute}-${now.second}_${UniqueKey().toString()}';
    // Directory tmp = await getTemporaryDirectory();
    // String tmpPath = '${tmp.path}/$nowString';

    // List<String> columeNames = [
    //   "uid",
    //   "App Name",
    //   "Package Name",
    //   "Amount",
    //   "Create Time"
    // ];

    // try {
    //   if (!Directory(tmpPath).existsSync()) {
    //     Directory(tmpPath).createSync();
    //   }

    //   if (!Directory(documentsDirectory).existsSync()) {
    //     Directory(documentsDirectory).createSync();
    //   }

    //   for (var i = 0; i < n; i++) {
    //     final Workbook workbook = Workbook();
    //     final Worksheet sheet = workbook.worksheets[0];
    //     sheet.showGridlines = true;
    //     sheet.enableSheetCalculations();
    //     var e = (i + 1) * c;
    //     var start = i * c, end = records.length < e ? (records.length % c) : e;
    //     var recordList = exportRecords.getRange(start, end);

    //     for (var k = 0; k < columeNames.length; k++) {
    //       final Range range =
    //           sheet.getRangeByName('${String.fromCharCode(65 + k)}1');
    //       range.setText(columeNames[k]);
    //       range.autoFit();
    //     }

    //     for (var r = 0; r < recordList.length; r++) {
    //       Record record = recordList.elementAt(r);

    //       for (var j = 0; j < columeNames.length; j++) {
    //         final Range range =
    //             sheet.getRangeByName('${String.fromCharCode(65 + j)}${2 + r}');
    //         switch (j) {
    //           case 0:
    //             range.setText(record.uid);
    //             break;
    //           case 1:
    //             range.setText(record.appName);
    //             break;
    //           case 2:
    //             range.setText(record.packageName);
    //             break;
    //           case 3:
    //             // range.set(record.isAd);
    //             break;
    //           case 4:
    //             range.setDateTime(record.createTime);
    //             break;
    //           default:
    //         }
    //         range.autoFit();
    //       }
    //     }

    //     final List<int> bytes = workbook.saveAsStream();
    //     File("$tmpPath/$start~$end.xlsx").writeAsBytes(bytes);
    //     workbook.dispose();
    //   }

    //   await ZipFile.createFromDirectory(
    //       sourceDir: Directory(tmpPath),
    //       zipFile: File('$documentsDirectory/$nowString.zip'),
    //       recurseSubDirs: true);
    //   Fluttertoast.showToast(msg: 'Save to the $documentsDirectory');
    // } catch (e) {
    //   Fluttertoast.showToast(msg: e.toString());
    // }
  }
}
