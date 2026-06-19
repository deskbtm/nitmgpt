import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/utils/local_model.dart';

void main() {
  group('displayNameFromFilename', () {
    test('strips file extension for active model title', () {
      expect(
        displayNameFromFilename('gemma-3-270m.task'),
        'gemma-3-270m',
      );
    });

    test('returns filename when there is no extension', () {
      expect(displayNameFromFilename('gemma-model'), 'gemma-model');
    });
  });

  group('filenameFromUrl', () {
    test('extracts last path segment', () {
      expect(
        filenameFromUrl(
          'https://huggingface.co/google/gemma-3-270m/resolve/main/gemma-3-270m.task',
        ),
        'gemma-3-270m.task',
      );
    });
  });

  group('filenameFromPath', () {
    test('extracts basename from unix path', () {
      expect(
        filenameFromPath('/storage/emulated/0/Download/gemma-3-270m.task'),
        'gemma-3-270m.task',
      );
    });

    test('extracts basename from windows path', () {
      expect(
        filenameFromPath(r'C:\Users\model\gemma-3-270m.task'),
        'gemma-3-270m.task',
      );
    });
  });

  group('inferFileKind', () {
    test('detects task files', () {
      expect(inferFileKind('model.task'), LocalModelFileKind.task);
    });

    test('detects litertlm files', () {
      expect(inferFileKind('model.litertlm'), LocalModelFileKind.litertlm);
    });

    test('defaults to binary for unknown extensions', () {
      expect(inferFileKind('model.bin'), LocalModelFileKind.binary);
    });
  });

  group('validateModelUrl', () {
    test('rejects blank URL', () {
      expect(validateModelUrl(''), 'Model URL is required');
      expect(validateModelUrl('   '), 'Model URL is required');
    });

    test('accepts non-empty URL', () {
      expect(
        validateModelUrl('https://example.com/model.task'),
        isNull,
      );
    });
  });

  group('validateModelFilePath', () {
    test('rejects blank path', () {
      expect(validateModelFilePath(''), 'Model file is required');
      expect(validateModelFilePath('   '), 'Model file is required');
    });

    test('accepts non-empty path', () {
      expect(
        validateModelFilePath('/tmp/model.task'),
        isNull,
      );
    });
  });

  group('validateModelFilename', () {
    test('accepts supported model extensions', () {
      expect(validateModelFilename('model.task'), isNull);
      expect(validateModelFilename('model.litertlm'), isNull);
      expect(validateModelFilename('model.bin'), isNull);
      expect(validateModelFilename('model.tflite'), isNull);
    });

    test('rejects unsupported extensions', () {
      expect(
        validateModelFilename('model.zip'),
        'Unsupported model file type',
      );
    });
  });

  group('shouldSkipConcurrentInstall', () {
    test('blocks when install is already in progress', () {
      expect(shouldSkipConcurrentInstall(isInstalling: true), isTrue);
    });

    test('allows when idle', () {
      expect(shouldSkipConcurrentInstall(isInstalling: false), isFalse);
    });
  });

  group('resolveInstalledModelFilePath', () {
    test('prefers file source path for local imports', () {
      expect(
        resolveInstalledModelFilePath(
          fileSourcePath: '/data/app/files/model_imports/Qwen3-0.6B.litertlm',
          externalPath: '/data/app/files/model_imports/legacy.litertlm',
          documentsPath: '/data/app/documents/Qwen3-0.6B.litertlm',
        ),
        '/data/app/files/model_imports/Qwen3-0.6B.litertlm',
      );
    });

    test('falls back to external path when file source is absent', () {
      expect(
        resolveInstalledModelFilePath(
          externalPath: '/data/app/files/model_imports/Qwen3-0.6B.litertlm',
          documentsPath: '/data/app/documents/Qwen3-0.6B.litertlm',
        ),
        '/data/app/files/model_imports/Qwen3-0.6B.litertlm',
      );
    });

    test('uses documents path for network downloads', () {
      expect(
        resolveInstalledModelFilePath(
          documentsPath: '/data/app/documents/gemma-3-270m.task',
        ),
        '/data/app/documents/gemma-3-270m.task',
      );
    });
  });
}
