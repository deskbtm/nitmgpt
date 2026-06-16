import 'dart:io';

import 'package:flutter_gemma/core/di/service_registry.dart';
import 'package:flutter_gemma/core/domain/model_source.dart';
import 'package:flutter_gemma/core/services/model_repository.dart' as model_repo;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

class GemmaModelEntry {
  const GemmaModelEntry({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.installedAt,
    required this.modelType,
    required this.fileType,
    required this.isActive,
    required this.hasLora,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final DateTime installedAt;
  final ModelType modelType;
  final ModelFileType fileType;
  final bool isActive;
  final bool hasLora;

  double get sizeMb => sizeBytes / (1024 * 1024);
}

class GemmaModelStore {
  static const _modelTypeKeyPrefix = 'nitmgpt_gemma_model_type_';
  static const _fileTypeKeyPrefix = 'nitmgpt_gemma_file_type_';

  final isLoading = signal(false);
  final isInstalling = signal(false);
  final installProgress = signal<int?>(null);
  final errorMessage = signal<String?>(null);
  final models = listSignal<GemmaModelEntry>([]);
  final activeModelId = signal<String?>(null);
  final storageStats = signal<StorageStats?>(null);
  final hasActiveModel = signal(false);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final manager = FlutterGemmaPlugin.instance.modelManager;
      await manager.ensureInitialized();

      hasActiveModel.value = FlutterGemma.hasActiveModel();

      String? activeId;
      final activeSpec = manager.activeInferenceModel;
      if (activeSpec is InferenceModelSpec) {
        activeId = activeSpec.files
            .firstWhere((f) => f.isRequired)
            .filename;
      }
      activeModelId.value = activeId;

      final repository = ServiceRegistry.instance.modelRepository;
      final installed = await repository.listInstalled();
      final inferenceModels = installed
          .where((info) => info.type == model_repo.ModelType.inference)
          .toList()
        ..sort((a, b) => b.installedAt.compareTo(a.installedAt));

      final prefs = await SharedPreferences.getInstance();
      final entries = <GemmaModelEntry>[];

      for (final info in inferenceModels) {
        final modelType = _readModelType(prefs, info.id);
        final fileType = _readFileType(prefs, info.id);
        entries.add(
          GemmaModelEntry(
            id: info.id,
            name: displayNameFromFilename(info.id),
            sizeBytes: info.sizeBytes,
            installedAt: info.installedAt,
            modelType: modelType,
            fileType: fileType,
            isActive: info.id == activeId,
            hasLora: info.hasLoraWeights,
          ),
        );
      }

      models.value = entries;
      storageStats.value = await manager.getStorageInfo();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> installFromNetwork({
    required String url,
    required ModelType modelType,
    ModelFileType fileType = ModelFileType.task,
    String? token,
  }) async {
    if (shouldSkipConcurrentInstall(isInstalling: isInstalling.value)) {
      return;
    }

    final trimmedUrl = url.trim();
    final validationError = validateModelUrl(trimmedUrl);
    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    isInstalling.value = true;
    installProgress.value = 0;
    errorMessage.value = null;

    try {
      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: fileType,
      )
          .fromNetwork(trimmedUrl, token: token)
          .withProgress((progress) => installProgress.value = progress)
          .install();

      final filename = filenameFromUrl(trimmedUrl);
      await _persistModelIdentity(filename, modelType, fileType);
      await refresh();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isInstalling.value = false;
      installProgress.value = null;
    }
  }

  Future<void> installFromFile({
    required String path,
    required ModelType modelType,
    ModelFileType? fileType,
  }) async {
    if (shouldSkipConcurrentInstall(isInstalling: isInstalling.value)) {
      return;
    }

    final trimmedPath = path.trim();
    final validationError = validateModelFilePath(trimmedPath);
    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    if (!File(trimmedPath).existsSync()) {
      errorMessage.value = 'Model file not found';
      return;
    }

    final filename = filenameFromPath(trimmedPath);
    final effectiveFileType =
        fileType ?? _fileTypeFromKind(inferFileKind(filename));

    isInstalling.value = true;
    installProgress.value = 0;
    errorMessage.value = null;

    try {
      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: effectiveFileType,
      )
          .fromFile(trimmedPath)
          .withProgress((progress) => installProgress.value = progress)
          .install();

      await _persistModelIdentity(filename, modelType, effectiveFileType);
      await refresh();
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isInstalling.value = false;
      installProgress.value = null;
    }
  }

  Future<void> setActive(String modelId) async {
    errorMessage.value = null;

    try {
      final repository = ServiceRegistry.instance.modelRepository;
      final info = await repository.loadModel(modelId);
      if (info == null) {
        throw StateError('Model not found: $modelId');
      }

      final prefs = await SharedPreferences.getInstance();
      final modelType = _readModelType(prefs, modelId);
      final fileType = _readFileType(prefs, modelId);

      final filePath = await ServiceRegistry.instance.fileSystemService
          .getReadTargetPath(modelId);
      if (!File(filePath).existsSync()) {
        throw StateError('Model file missing on disk: $modelId');
      }

      final spec = InferenceModelSpec(
        name: displayNameFromFilename(modelId),
        modelSource: FileSource(filePath),
        modelType: modelType,
        fileType: fileType,
      );

      final manager = FlutterGemmaPlugin.instance.modelManager;
      await manager.ensureModelReadyFromSpec(spec);
      await refresh();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  Future<void> uninstall(String modelId) async {
    errorMessage.value = null;

    try {
      await FlutterGemma.uninstallModel(modelId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_modelTypeKeyPrefix$modelId');
      await prefs.remove('$_fileTypeKeyPrefix$modelId');
      await refresh();
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  Future<int> cleanupOrphans() async {
    errorMessage.value = null;

    try {
      final manager = FlutterGemmaPlugin.instance.modelManager;
      final deleted = await manager.cleanupStorage();
      await refresh();
      return deleted;
    } catch (e) {
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  Future<void> _persistModelIdentity(
    String filename,
    ModelType modelType,
    ModelFileType fileType,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_modelTypeKeyPrefix$filename', modelType.name);
    await prefs.setString('$_fileTypeKeyPrefix$filename', fileType.name);
  }

  ModelType _readModelType(SharedPreferences prefs, String id) {
    final stored = prefs.getString('$_modelTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelType.values.byName(stored);
      } catch (_) {}
    }
    return ModelType.general;
  }

  ModelFileType _readFileType(SharedPreferences prefs, String id) {
    final stored = prefs.getString('$_fileTypeKeyPrefix$id');
    if (stored != null) {
      try {
        return ModelFileType.values.byName(stored);
      } catch (_) {}
    }
    return _fileTypeFromKind(inferFileKind(id));
  }

  static ModelFileType _fileTypeFromKind(GemmaModelFileKind kind) {
    return switch (kind) {
      GemmaModelFileKind.task => ModelFileType.task,
      GemmaModelFileKind.litertlm => ModelFileType.litertlm,
      GemmaModelFileKind.binary => ModelFileType.binary,
    };
  }
}
