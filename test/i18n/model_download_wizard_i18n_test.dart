import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/i18n/en_US.dart';
import 'package:nitmgpt/i18n/zh_CN.dart';
import 'package:nitmgpt/utils/model_download_guide.dart';

void main() {
  final wizardKeys = <String>[
    'Get a model',
    'Model download guide',
    'ModelScope (China) or Hugging Face',
    'Choose where to download based on your network.',
    'ModelScope (China)',
    'Hugging Face',
    'ModelScope (China) label',
    'Recommended for users in mainland China.',
    'Recommended for users outside mainland China.',
    'Open ModelScope',
    'Open Hugging Face',
    'Continue to download',
    'Close',
    'How to get a download URL?',
    ...ModelDownloadGuide.stepKeys(ModelDownloadSource.modelScope),
    ...ModelDownloadGuide.stepKeys(ModelDownloadSource.huggingFace),
    ...ModelDownloadGuide.tipKeys(ModelDownloadSource.modelScope),
    ...ModelDownloadGuide.tipKeys(ModelDownloadSource.huggingFace),
  ];

  test('model download wizard keys exist in en_US and zh_CN', () {
    for (final key in wizardKeys) {
      expect(en_US.containsKey(key), isTrue, reason: 'missing en_US: $key');
      expect(zh_CN.containsKey(key), isTrue, reason: 'missing zh_CN: $key');
    }
  });

  test('model download wizard zh_CN entries are localized', () {
    expect(zh_CN['Model download guide'], '模型下载向导');
    expect(zh_CN['Open ModelScope'], '打开魔搭 ModelScope');
    expect(zh_CN['Close'], '关闭');
  });
}
