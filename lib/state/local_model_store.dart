import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/core/di/service_registry.dart';
import 'package:flutter_gemma/core/domain/model_source.dart';
import 'package:flutter_gemma/core/services/model_repository.dart'
    as model_repo;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/core/safe_signal_write.dart';
import 'package:nitmgpt/platform/litert_backend.dart';
import 'package:nitmgpt/platform/model_file_picker.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';
import 'package:nitmgpt/state/local_model_inference_prefs.dart';
import 'package:nitmgpt/state/local_model_prefs.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LocalModelEntry {
  const LocalModelEntry({
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

class LocalModelStore {
  LocalModelStore({
    LocalModelIdentityPrefs? identityPrefs,
    LocalModelInferencePrefs? inferencePrefs,
  })  : _identityPrefs = identityPrefs ?? LocalModelIdentityPrefs(),
        _inferencePrefs = inferencePrefs;

  final LocalModelIdentityPrefs _identityPrefs;
  final LocalModelInferencePrefs? _inferencePrefs;

  final isLoading = signal(false);
  final isInstalling = signal(false);
  final installProgress = signal<int?>(null);
  final errorMessage = signal<String?>(null);
  final models = listSignal<LocalModelEntry>([]);
  final activeModelId = signal<String?>(null);
  final storageStats = signal<StorageStats?>(null);
  final hasActiveModel = signal(false);

  bool _initialized = false;

  Future<void> _ensureGemmaReady() => ensureFlutterGemmaInitialized();

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    await _ensureGemmaReady();
    safeSignalWrite(() {
      isLoading.value = true;
      errorMessage.value = null;
    });

    try {
      final manager = FlutterGemmaPlugin.instance.modelManager;
      await manager.ensureInitialized();

      final hasActive = FlutterGemma.hasActiveModel();

      String? activeId;
      final activeSpec = manager.activeInferenceModel;
      if (activeSpec is InferenceModelSpec) {
        activeId = activeSpec.files.firstWhere((f) => f.isRequired).filename;
      }

      final repository = ServiceRegistry.instance.modelRepository;
      final installed = await repository.listInstalled();
      final inferenceModels = installed
          .where((info) => info.type == model_repo.ModelType.inference)
          .toList()
        ..sort((a, b) => b.installedAt.compareTo(a.installedAt));

      final entries = <LocalModelEntry>[];

      for (final info in inferenceModels) {
        final modelType = _identityPrefs.readModelType(info.id);
        final fileType = _identityPrefs.readFileType(info.id);
        final sizeBytes = await _resolveSizeBytes(info);
        entries.add(
          LocalModelEntry(
            id: info.id,
            name: displayNameFromFilename(info.id),
            sizeBytes: sizeBytes,
            installedAt: info.installedAt,
            modelType: modelType,
            fileType: fileType,
            isActive: info.id == activeId,
            hasLora: info.hasLoraWeights,
          ),
        );
      }

      final pluginStats = await manager.getStorageInfo();
      final modelTotalBytes =
          entries.fold<int>(0, (sum, entry) => sum + entry.sizeBytes);
      final stats = StorageStats(
        totalFiles: entries.isNotEmpty ? entries.length : pluginStats.totalFiles,
        totalSizeBytes:
            modelTotalBytes > 0 ? modelTotalBytes : pluginStats.totalSizeBytes,
        orphanedFiles: pluginStats.orphanedFiles,
      );
      safeSignalWrite(() {
        hasActiveModel.value = hasActive;
        activeModelId.value = activeId;
        models.value = entries;
        storageStats.value = stats;
      });
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
    } finally {
      safeSignalWrite(() => isLoading.value = false);
    }
  }

  Future<void> installFromNetwork({
    required String url,
    required ModelType modelType,
    ModelFileType fileType = ModelFileType.task,
    String? token,
  }) async {
    await _ensureGemmaReady();
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
          .withProgress(
            (progress) =>
                safeSignalWrite(() => installProgress.value = progress),
          )
          .install();

      final filename = filenameFromUrl(trimmedUrl);
      await _persistModelIdentity(filename, modelType, fileType);
      await refresh();
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
    } finally {
      safeSignalWrite(() {
        isInstalling.value = false;
        installProgress.value = null;
      });
    }
  }

  Future<void> installFromPickedFile({
    required PickedModelFile picked,
    required ModelType modelType,
  }) async {
    await _ensureGemmaReady();
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
        LocalModelIdentityPrefs.fileTypeFromKind(inferFileKind(filename));

    isInstalling.value = true;
    installProgress.value = 0;
    errorMessage.value = null;

    try {
      final path = await ModelFilePicker.ensureFilesystemPath(
        picked: picked,
        onProgress: (progress) =>
            safeSignalWrite(() => installProgress.value = progress),
      );

      if (!File(path).existsSync()) {
        safeSignalWrite(() => errorMessage.value = 'Model file not found');
        return;
      }

      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: effectiveFileType,
      )
          .fromFile(path)
          .withProgress(
            (progress) =>
                safeSignalWrite(() => installProgress.value = progress),
          )
          .install();

      await _persistModelIdentity(filename, modelType, effectiveFileType);
      await refresh();
    } on PlatformException catch (error) {
      safeSignalWrite(() {
        if (error.code == 'enospc') {
          errorMessage.value = 'Not enough storage space';
        } else if (error.message != null && error.message!.isNotEmpty) {
          errorMessage.value = error.message!;
        } else {
          errorMessage.value = 'Could not read selected file';
        }
      });
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
    } finally {
      safeSignalWrite(() {
        isInstalling.value = false;
        installProgress.value = null;
      });
    }
  }

  Future<void> installFromFile({
    required String path,
    required ModelType modelType,
    ModelFileType? fileType,
  }) async {
    await _ensureGemmaReady();
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
        LocalModelIdentityPrefs.fileTypeFromKind(inferFileKind(filename));

    isInstalling.value = true;
    installProgress.value = 0;
    errorMessage.value = null;

    try {
      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: effectiveFileType,
      )
          .fromFile(trimmedPath)
          .withProgress(
            (progress) =>
                safeSignalWrite(() => installProgress.value = progress),
          )
          .install();

      await _persistModelIdentity(filename, modelType, effectiveFileType);
      await refresh();
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
    } finally {
      safeSignalWrite(() {
        isInstalling.value = false;
        installProgress.value = null;
      });
    }
  }

  Future<void> setActive(String modelId) async {
    await _ensureGemmaReady();
    safeSignalWrite(() => errorMessage.value = null);

    try {
      final repository = ServiceRegistry.instance.modelRepository;
      final info = await repository.loadModel(modelId);
      if (info == null) {
        throw StateError('Model not found: $modelId');
      }

      final modelType = _identityPrefs.readModelType(modelId);
      final fileType = _identityPrefs.readFileType(modelId);

      if (fileType == ModelFileType.litertlm) {
        await ensureLitertLmRuntimeSupported();
      }

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
      final message = e is UnsupportedError &&
              e.message == kLitertLmEmulatorUnsupportedKey
          ? kLitertLmEmulatorUnsupportedKey
          : e.toString();
      safeSignalWrite(() => errorMessage.value = message);
    }
  }

  Future<void> uninstall(String modelId) async {
    await _ensureGemmaReady();
    safeSignalWrite(() => errorMessage.value = null);

    try {
      await FlutterGemma.uninstallModel(modelId);
      await _identityPrefs.remove(modelId);
      await _inferencePrefs?.remove(modelId);
      await refresh();
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
    }
  }

  Future<int> cleanupOrphans() async {
    safeSignalWrite(() => errorMessage.value = null);

    try {
      final manager = FlutterGemmaPlugin.instance.modelManager;
      final deleted = await manager.cleanupStorage();
      await refresh();
      return deleted;
    } catch (e) {
      safeSignalWrite(() => errorMessage.value = e.toString());
      return 0;
    }
  }

  Future<int> _resolveSizeBytes(model_repo.ModelInfo info) async {
    try {
      final registry = ServiceRegistry.instance;
      final fileSourcePath =
          info.source is FileSource ? (info.source as FileSource).path : null;
      final externalPath =
          await registry.protectedFilesRegistry.getExternalPath(info.id);
      final documentsPath =
          await registry.fileSystemService.getReadTargetPath(info.id);
      final filePath = resolveInstalledModelFilePath(
        fileSourcePath: fileSourcePath,
        externalPath: externalPath,
        documentsPath: documentsPath,
      );
      final file = File(filePath);
      if (file.existsSync()) {
        return file.lengthSync();
      }
    } catch (_) {}

    return info.sizeBytes > 0 ? info.sizeBytes : 0;
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
