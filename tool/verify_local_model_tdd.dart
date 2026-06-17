import 'package:nitmgpt/i18n/en_US.dart';
import 'package:nitmgpt/i18n/zh_CN.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';

/// Offline TDD verification — avoids flutter_gemma native init in flutter test.
void main() {
  _check(
    displayNameFromFilename('gemma-3-270m.task') == 'gemma-3-270m',
    'displayNameFromFilename strips extension',
  );
  _check(
    displayNameFromFilename('gemma-model') == 'gemma-model',
    'displayNameFromFilename without extension',
  );
  _check(
    filenameFromUrl(
          'https://huggingface.co/google/gemma-3-270m/resolve/main/gemma-3-270m.task',
        ) ==
        'gemma-3-270m.task',
    'filenameFromUrl',
  );
  _check(inferFileKind('model.task') == LocalModelFileKind.task, 'inferFileKind task');
  _check(
    inferFileKind('model.litertlm') == LocalModelFileKind.litertlm,
    'inferFileKind litertlm',
  );
  _check(
    inferFileKind('model.bin') == LocalModelFileKind.binary,
    'inferFileKind binary',
  );
  _check(validateModelUrl('') == 'Model URL is required', 'validateModelUrl empty');
  _check(validateModelUrl('   ') == 'Model URL is required', 'validateModelUrl blank');
  _check(
    validateModelUrl('https://example.com/model.task') == null,
    'validateModelUrl valid',
  );
  _check(
    shouldSkipConcurrentInstall(isInstalling: true),
    'shouldSkipConcurrentInstall when busy',
  );
  _check(
    !shouldSkipConcurrentInstall(isInstalling: false),
    'shouldSkipConcurrentInstall when idle',
  );
  _check(
    en_US['Cleanup completed'] == 'History cleared',
    'history cleanup i18n en',
  );
  _check(
    en_US['Storage cleanup completed'] == 'Storage cleanup completed',
    'storage cleanup i18n en',
  );
  _check(
    zh_CN['Storage cleanup completed'] == '存储清理完成',
    'storage cleanup i18n zh',
  );

  // ignore: avoid_print
  print('All 14 TDD checks passed.');
}

void _check(bool condition, String name) {
  if (!condition) {
    throw StateError('FAIL: $name');
  }
}
