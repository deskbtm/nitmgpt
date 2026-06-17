import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/prefs_signal.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';

/// SharedPreferences-backed local model identity (type + file format per filename).
class LocalModelIdentityPrefs {
  // Legacy key prefixes — keep for existing installs.
  static const modelTypeKeyPrefix = 'nitmgpt_gemma_model_type_';
  static const fileTypeKeyPrefix = 'nitmgpt_gemma_file_type_';

  ModelType readModelType(String id) {
    final stored = readPrefString('$modelTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelType.values.byName(stored);
      } catch (_) {}
    }
    return ModelType.general;
  }

  ModelFileType readFileType(String id) {
    final stored = readPrefString('$fileTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelFileType.values.byName(stored);
      } catch (_) {}
    }
    return fileTypeFromKind(inferFileKind(id));
  }

  Future<void> write({
    required String id,
    required ModelType modelType,
    required ModelFileType fileType,
  }) async {
    await writePrefString('$modelTypeKeyPrefix$id', modelType.name);
    await writePrefString('$fileTypeKeyPrefix$id', fileType.name);
  }

  Future<void> remove(String id) async {
    await removePref('$modelTypeKeyPrefix$id');
    await removePref('$fileTypeKeyPrefix$id');
  }

  static ModelFileType fileTypeFromKind(LocalModelFileKind kind) {
    return switch (kind) {
      LocalModelFileKind.task => ModelFileType.task,
      LocalModelFileKind.litertlm => ModelFileType.litertlm,
      LocalModelFileKind.binary => ModelFileType.binary,
    };
  }
}
