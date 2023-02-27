import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/pages/add_rules/add_rules_controller.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:get/get.dart';
import 'i18n/i18n.dart';
import 'constants.dart';
import 'models/rule.dart';
import 'notification_utils.dart';
import 'pages/home/watcher_controller.dart';
import 'routes.dart';
import 'theme.dart';

class NITM extends StatefulWidget {
  const NITM({super.key});

  @override
  State<StatefulWidget> createState() {
    return _PITMState();
  }
}

class _PITMState extends State<NITM> {
  static final ReceivePort _notificationPort = ReceivePort();

  // prevent dart from stripping out this function on release build in Flutter 3.x
  @pragma('vm:entry-point')
  static void _callback(NotificationEvent event) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName(NOTIFICATION_LISTENER);

    send?.send(event);
  }

  static _requestCallback(Rule rule, Record record) async {
    var r = record.toMap();
    switch (rule.callbackHttpMethod) {
      case "GET":
        await GetConnect().get(rule.callbackUrl, query: r);
        break;
      case "POST":
        await GetConnect().post(rule.callbackUrl, r);
        break;
      case "PUT":
        await GetConnect().put(rule.callbackUrl, r);
        break;
    }
  }

  // Note Bene:
  // In some distros will trigger twice.
  // Here it runs in a separate service, it's not shared memory, class need to re-instantiate.
  static void _handleNotificationListener(NotificationEvent event) async {
    if (event.id != null) {
      Timer(Duration(seconds: 5), () {
        NotificationsListener.cancelNotification(event.key ?? '');
        // LocalNotification.plugin.cancel(event.id!);
        print('afterTimer = ' + DateTime.now().toString());
      });
    }

    // if (event.title == null) {
    //   return;
    // }
    // var rules = RulesController.to.rules;
    // var watcher = WatcherController.to;

    // Rule? rule = rules.firstWhereOrNull(
    //     (element) => element.packageName == event.packageName);

    // String matchString = '${event.title}&&${event.text ?? ''}';

    // if (rule != null) {
    //   var amount = RegExp(
    //     rule.matchPattern,
    //     caseSensitive: false,
    //     multiLine: false,
    //   ).firstMatch(matchString)?.group(0);
    //   Record record = Record()
    //     ..amount = amount ?? '0'
    //     ..appName = rule.appName
    //     ..packageName = rule.packageName
    //     ..notificationText = event.text ?? ''
    //     ..notificationTitle = event.title ?? ''
    //     ..timestamp = event.timestamp ?? 0
    //     ..createTime = event.createAt!
    //     ..uid = event.uniqueId ?? '';

    //   if (amount != null && amount != '0') {
    //     await watcher.addRecord(record);
    //     await _requestCallback(rule, record);
    //   }
    // }
  }

  static void _initNotificationListener() async {
    // NotificationsListener.initialize(callbackHandle: _callback);
    await NotificationsListener.initialize();

    NotificationsListener.receivePort
        ?.listen((message) => _handleNotificationListener(message));

    // IsolateNameServer.removePortNameMapping(NOTIFICATION_LISTENER);
    // IsolateNameServer.registerPortWithName(
    //     _notificationPort.sendPort, NOTIFICATION_LISTENER);

    // _notificationPort.listen((message) => _handleNotificationListener(message));
  }

  @override
  void initState() {
    super.initState();
    Get.put(WatcherController());
    Get.put(RulesController(), permanent: true);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await LocalNotification.init();
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        initialNotificationTitle: 'AWESOME SERVICE',
        initialNotificationContent: 'Initializing',
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

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

    _initNotificationListener();
  }

  // startBackgroundService() async {
  //   final service = FlutterBackgroundService();
  //   await service.configure(
  //     androidConfiguration: AndroidConfiguration(
  //       // auto start service
  //       autoStart: true,
  //       isForegroundMode: true,
  //       notificationChannelId: 'nitm_foreground',
  //       initialNotificationTitle: 'NITM running....',
  //       initialNotificationContent:
  //           'Background notification for keeping the nitm running in the background',
  //       foregroundServiceNotificationId: 888,
  //       onStart: onStart,
  //     ),
  //     iosConfiguration: IosConfiguration(),
  //   );

  //   service.startService();
  // }

  @override
  void dispose() async {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: GetMaterialApp(
            defaultTransition: Transition.native,
            enableLog: true,
            translations: TranslationService(),
            locale: TranslationService.locale,
            fallbackLocale: TranslationService.fallbackLocale,
            navigatorObservers: [
              SentryNavigatorObserver(),
              FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)
            ],
            initialRoute: '/',
            getPages: routes,
            theme: lightThemeData,
          ),
        );
      },
      // child: DoublePopExit(),
    );
  }
}
