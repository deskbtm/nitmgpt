import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/realm_kv.dart';
import 'package:nitmgpt/utils/local_model.dart';

/// Realm KV-backed local model identity (type + file format per filename).
class LocalModelIdentityKv {
  static const modelTypeKeyPrefix = 'nitmgpt_gemma_model_type_';
  static const fileTypeKeyPrefix = 'nitmgpt_gemma_file_type_';

  ModelType readModelType(String id) {
    final stored = readKvString('$modelTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelType.values.byName(stored);
      } catch (_) {}
    }
    return ModelType.general;
  }

  ModelFileType readFileType(String id) {
    final stored = readKvString('$fileTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelFileType.values.byName(stored);
      } catch (_) {}
    }
    return fileTypeFromKind(inferFileKind(id));
  }

  void write({
    required String id,
    required ModelType modelType,
    required ModelFileType fileType,
  }) {
    writeKvString('$modelTypeKeyPrefix$id', modelType.name);
    writeKvString('$fileTypeKeyPrefix$id', fileType.name);
  }

  void remove(String id) {
    removeKvKey('$modelTypeKeyPrefix$id');
    removeKvKey('$fileTypeKeyPrefix$id');
  }

  static ModelFileType fileTypeFromKind(LocalModelFileKind kind) {
    return switch (kind) {
      LocalModelFileKind.task => ModelFileType.task,
      LocalModelFileKind.litertlm => ModelFileType.litertlm,
      LocalModelFileKind.binary => ModelFileType.binary,
    };
  }
}
