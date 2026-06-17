import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';

class PickedModelFile {
  const PickedModelFile({
    required this.name,
    this.filesystemPath,
    this.contentUri,
    this.sizeBytes,
  });

  final String name;
  final String? filesystemPath;
  final String? contentUri;
  final int? sizeBytes;

  bool get needsContentCopy =>
      contentUri != null &&
      (filesystemPath == null || filesystemPath!.trim().isEmpty);
}

class ModelFilePicker {
  static const _channel = MethodChannel('com.deskbtm.nitmgpt/model_file');
  static const _progressChannel =
      EventChannel('com.deskbtm.nitmgpt/model_file_progress');

  static Future<PickedModelFile?> pick() async {
    if (!kIsWeb && Platform.isAndroid) {
      return _pickOnAndroid();
    }
    return _pickWithFilePicker();
  }

  static Future<String> ensureFilesystemPath({
    required PickedModelFile picked,
    void Function(int progress)? onProgress,
  }) async {
    final directPath = picked.filesystemPath?.trim();
    if (directPath != null &&
        directPath.isNotEmpty &&
        File(directPath).existsSync()) {
      return directPath;
    }

    final uri = picked.contentUri?.trim();
    if (uri == null || uri.isEmpty) {
      throw PlatformException(
        code: 'invalid_file',
        message: 'Could not read selected file',
      );
    }

    StreamSubscription<dynamic>? progressSub;
    if (onProgress != null) {
      progressSub = _progressChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is int) {
            onProgress(event);
          }
        },
      );
    }

    try {
      final path = await _channel.invokeMethod<String>('copyModelFile', {
        'uri': uri,
        'fileName': picked.name,
      });
      if (path == null || path.isEmpty) {
        throw PlatformException(
          code: 'io_error',
          message: 'Could not read selected file',
        );
      }
      onProgress?.call(100);
      return path;
    } on PlatformException catch (error) {
      if (error.code == 'enospc') {
        throw PlatformException(
          code: error.code,
          message: 'Not enough storage space',
        );
      }
      rethrow;
    } finally {
      await progressSub?.cancel();
    }
  }

  static Future<PickedModelFile?> _pickOnAndroid() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'pickModelFile',
      );
      if (result == null) {
        return null;
      }

      final name = result['name']?.toString();
      if (name == null || name.isEmpty) {
        throw PlatformException(
          code: 'invalid_file',
          message: 'Could not read selected file',
        );
      }

      final sizeValue = result['size'];
      return PickedModelFile(
        name: name,
        contentUri: result['uri']?.toString(),
        sizeBytes: sizeValue is int ? sizeValue : int.tryParse('$sizeValue'),
      );
    } on PlatformException catch (error) {
      if (error.code == 'invalid_file') {
        rethrow;
      }
      throw PlatformException(
        code: error.code,
        message: error.message ?? 'Could not read selected file',
      );
    }
  }

  static Future<PickedModelFile?> _pickWithFilePicker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['task', 'litertlm', 'bin', 'tflite'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final name = file.name;
    if (name.isEmpty) {
      throw PlatformException(
        code: 'invalid_file',
        message: 'Could not read selected file',
      );
    }

    return PickedModelFile(
      name: name,
      filesystemPath: file.path,
      contentUri: file.identifier,
      sizeBytes: file.size,
    );
  }
}

String? validatePickedModelFile(PickedModelFile? picked) {
  if (picked == null) {
    return 'Model file is required';
  }
  return validateModelFilename(picked.name);
}

String detectedFileTypeLabel(String filename) {
  return switch (inferFileKind(filename)) {
    GemmaModelFileKind.task => 'task',
    GemmaModelFileKind.litertlm => 'litertlm',
    GemmaModelFileKind.binary => 'binary',
  };
}
