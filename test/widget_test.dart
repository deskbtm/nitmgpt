import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';

void main() {
  test('tr resolves zh_CN translations', () {
    setAppLocale(const Locale('zh', 'CN'));
    expect('Home'.tr, '首页');
    expect('Settings'.tr, '设置');
  });

  test('tr falls back to key for unknown entries', () {
    setAppLocale(const Locale('en', 'US'));
    expect('unknown_key_xyz'.tr, 'unknown_key_xyz');
  });
}
