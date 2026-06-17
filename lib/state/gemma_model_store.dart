import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/core/di/service_registry.dart';
import 'package:flutter_gemma/core/domain/model_source.dart';
import 'package:flutter_gemma/core/services/model_repository.dart'
    as model_repo;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/platform/model_file_picker.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';
import 'package:nitmgpt/state/gemma_model_prefs.dart';
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
  GemmaModelStore({GemmaModelIdentityPrefs? identityPrefs})
      : _identityPrefs = identityPrefs ?? GemmaModelIdentityPrefs();

  final GemmaModelIdentityPrefs _identityPrefs;

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
        activeId = activeSpec.files.firstWhere((f) => f.isRequired).filename;
      }
      activeModelId.value = activeId;

      final repository = ServiceRegistry.instance.modelRepository;
      final installed = await repository.listInstalled();
      final inferenceModels = installed
          .where((info) => info.type == model_repo.ModelType.inference)
          .toList()
        ..sort((a, b) => b.installedAt.compareTo(a.installedAt));

      final entries = <GemmaModelEntry>[];

      for (final info in inferenceModels) {
        final modelType = _identityPrefs.readModelType(info.id);
        final fileType = _identityPrefs.readFileType(info.id);
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

  Future<void> installFromPickedFile({
    required PickedModelFile picked,
    required ModelType modelType,
  }) async {
    if (shouldSkipConcurrentInstall(isInstalling: isInstalling.value)) {
      return;
    }

    final validationError = validateModelFilename(picked.name);
    if (validationError != null) {
      errorMessage.value = validationError;
      return;
    }

    final filename = picked.name;
    final effectiveFileType =
        GemmaModelIdentityPrefs.fileTypeFromKind(inferFileKind(filename));

    isInstalling.value = true;
    installProgress.value = 0;
    errorMessage.value = null;

    try {
      final path = await ModelFilePicker.ensureFilesystemPath(
        picked: picked,
        onProgress: (progress) => installProgress.value = progress,
      );

      if (!File(path).existsSync()) {
        errorMessage.value = 'Model file not found';
        return;
      }

      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: effectiveFileType,
      )
          .fromFile(path)
          .withProgress((progress) => installProgress.value = progress)
          .install();

      await _persistModelIdentity(filename, modelType, effectiveFileType);
      await refresh();
    } on PlatformException catch (error) {
      if (error.code == 'enospc') {
        errorMessage.value = 'Not enough storage space';
      } else if (error.message != null && error.message!.isNotEmpty) {
        errorMessage.value = error.message!;
      } else {
        errorMessage.value = 'Could not read selected file';
      }
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
    final effectiveFileType = fileType ??
        GemmaModelIdentityPrefs.fileTypeFromKind(inferFileKind(filename));

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

      final modelType = _identityPrefs.readModelType(modelId);
      final fileType = _identityPrefs.readFileType(modelId);

      final registry = ServiceRegistry.instance;
      final fileSourcePath =
          info.source is FileSource ? (info.source as FileSource).path : null;
      final externalPath =
          await registry.protectedFilesRegistry.getExternalPath(modelId);
      final documentsPath =
          await registry.fileSystemService.getReadTargetPath(modelId);
      final filePath = resolveInstalledModelFilePath(
        fileSourcePath: fileSourcePath,
        externalPath: externalPath,
        documentsPath: documentsPath,
      );
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
      await _identityPrefs.remove(modelId);
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
  ) {
    return _identityPrefs.write(
      id: filename,
      modelType: modelType,
      fileType: fileType,
    );
  }
}
