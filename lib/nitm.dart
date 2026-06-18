import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nitmgpt/app/app_router.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';

class NITM extends StatefulWidget {
  const NITM({super.key});

  @override
  State<NITM> createState() => _NITMState();
}

class _NITMState extends State<NITM> {
  @override
  Widget build(BuildContext context) {
    log('Root re-render', name: 'NITM');

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return SignalBuilder(
          builder: (context) {
            final locale = appLocale.value;
            return MaterialApp.router(
              routerConfig: appRouter,
              locale: locale,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('zh', 'CN'),
              ],
              theme: lightThemeData,
            );
          },
        );
      },
    );
  }
}
