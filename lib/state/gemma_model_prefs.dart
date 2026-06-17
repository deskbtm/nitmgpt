import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/prefs_signal.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';

/// SharedPreferences-backed Gemma model identity (type + file format per filename).
class GemmaModelIdentityPrefs {
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

  static ModelFileType fileTypeFromKind(GemmaModelFileKind kind) {
    return switch (kind) {
      GemmaModelFileKind.task => ModelFileType.task,
      GemmaModelFileKind.litertlm => ModelFileType.litertlm,
      GemmaModelFileKind.binary => ModelFileType.binary,
    };
  }
}
