import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/i18n/en_US.dart';
import 'package:nitmgpt/i18n/zh_CN.dart';

void main() {
  test('storage cleanup title is distinct from history cleanup in en_US', () {
    expect(en_US['Cleanup completed'], 'History cleared');
    expect(en_US['Storage cleanup completed'], 'Storage cleanup completed');
  });

  test('storage cleanup title is translated in zh_CN', () {
    expect(zh_CN['Storage cleanup completed'], '存储清理完成');
  });
}
