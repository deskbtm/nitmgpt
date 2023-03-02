import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/pages/settings/settings_controller.dart';
import 'i18n/i18n.dart';
import 'notification_utils.dart';
import 'pages/home/watcher_controller.dart';
import 'routes.dart';
import 'theme.dart';

class NITM extends StatefulWidget {
  const NITM({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NITMState();
  }
}

class _NITMState extends State<NITM> {
  @override
  void initState() {
    super.initState();
    Get.put(SettingsController(), permanent: true);
    Get.put(WatcherController(), permanent: true);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await LocalNotification.init();
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
