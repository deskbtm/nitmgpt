import 'package:flutter/material.dart';

/// Locale codes used when persisting user language preference.
class TranslationService {
  static const fallbackLocale = Locale('zh', 'CN');
  static const enUS = Locale('en', 'US');
  static const zhCN = Locale('zh', 'CN');

  static Locale? from(String? code) {
    switch (code) {
      case 'en_US':
        return enUS;
      case 'zh_CN':
        return zhCN;
      default:
        return null;
    }
  }
}
