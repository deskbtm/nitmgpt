import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'en_US.dart';
import 'zh_CN.dart';

class TranslationService extends Translations {
  static Locale? get locale => Get.deviceLocale;

  static const fallbackLocale = Locale('zh', 'CN');

  static const enUS = Locale('en', 'US');
  static const zhCN = Locale('zh', 'CN');

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': en_US,
        'zh_CN': zh_CN,
      };
}
