import 'package:flutter/material.dart';
import 'package:nitmgpt/core/safe_signal_write.dart';
import 'package:signals/signals.dart';
import 'package:nitmgpt/i18n/en_US.dart';
import 'package:nitmgpt/i18n/zh_CN.dart';

final appLocale = signal<Locale>(const Locale('zh', 'CN'));

Locale localeFromLanguageCode(String? code) {
  switch (code) {
    case 'en_US':
      return const Locale('en', 'US');
    case 'zh_CN':
      return const Locale('zh', 'CN');
    default:
      return const Locale('zh', 'CN');
  }
}

Map<String, String> translationsFor(Locale locale) {
  if (locale.languageCode == 'zh') return zh_CN;
  return en_US;
}

extension AppLocalizations on String {
  String get tr {
    final map = translationsFor(appLocale.value);
    return map[this] ?? this;
  }
}

void setAppLocale(Locale locale) {
  safeSignalWrite(() => appLocale.value = locale);
}
