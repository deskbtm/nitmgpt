import 'dart:ui';
import 'dart:isolate';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final ReceivePort _notificationPort = ReceivePort();

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

  // Note Bene: In some distros will trigger twice.
  static void _handleNotificationListener(NotificationEvent event) async {
    if (event.title == null) {
      return;
    }
    var rules = RulesController.to.rules;
    var watcher = WatcherController.to;

    Rule? rule = rules.firstWhereOrNull(
        (element) => element.packageName == event.packageName);

    String matchString = '${event.title}&&${event.text ?? ''}';

    if (rule != null) {
      var amount = RegExp(
        rule.matchPattern,
        caseSensitive: false,
        multiLine: false,
      ).firstMatch(matchString)?.group(0);
      Record record = Record()
        ..amount = amount ?? '0'
        ..appName = rule.appName
        ..packageName = rule.packageName
        ..notificationText = event.text ?? ''
        ..notificationTitle = event.title ?? ''
        ..timestamp = event.timestamp ?? 0
        ..createTime = event.createAt!
        ..uid = event.uniqueId ?? '';

      if (amount != null && amount != '0') {
        await watcher.addRecord(record);
        await _requestCallback(rule, record);
      }
    }
  }

  void _initListener() {
    NotificationsListener.initialize(callbackHandle: _callback);

    IsolateNameServer.removePortNameMapping(NOTIFICATION_LISTENER);
    IsolateNameServer.registerPortWithName(
        _notificationPort.sendPort, NOTIFICATION_LISTENER);

    _notificationPort.listen((message) => _handleNotificationListener(message));
  }

  @override
  void initState() {
    super.initState();
    Get.put(WatcherController());
    Get.put(RulesController(), permanent: true);
    _initListener();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await LocalNotification.init();
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
