import 'dart:ui';
import 'dart:isolate';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nitmgpt/hive_fields_mgmt.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:get/get.dart';
import 'i18n/i18n.dart';
import 'constants.dart';
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
  // prevent dart from stripping out this function on release build in Flutter 3.x
  @pragma('vm:entry-point')
  static void _callback(NotificationEvent event) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName(NOTIFICATION_LISTENER);

    send?.send(event);
  }

  @override
  void initState() {
    super.initState();
    Get.put(WatcherController());
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
        initialNotificationTitle: 'NITMGPT SERVICE',
        initialNotificationContent: 'running...',
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  @pragma('vm:entry-point')
  static onStart(ServiceInstance service) async {
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

    await permanentListenerServiceMain();
  }

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
