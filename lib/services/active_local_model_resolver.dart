import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_gemma/core/di/service_registry.dart';
import 'package:flutter_gemma/core/domain/model_source.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/platform/litert_backend.dart';
import 'package:nitmgpt/state/local_model_active_kv.dart';
import 'package:nitmgpt/utils/local_model.dart';
import 'package:nitmgpt/state/local_model_identity_kv.dart';
import 'package:nitmgpt/state/local_model_inference_kv.dart';

const _logName = 'active_local_model';

Completer<String?>? _restoreCompleter;

/// Resolved active model shared by test chat and notification filtering.
class ActiveLocalModelContext {
  const ActiveLocalModelContext({
    required this.modelId,
    required this.spec,
    required this.inferenceConfig,
  });

  final String modelId;
  final InferenceModelSpec spec;
  final LocalModelInferenceConfig inferenceConfig;

  String get displayLabel => displayNameFromFilename(modelId);

  ModelType get modelType => spec.modelType;
}

/// Filename of the active inference model in [FlutterGemma], if any.
String? readActiveLocalModelIdFromManager() {
  final activeSpec =
      FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
  if (activeSpec is! InferenceModelSpec) {
    return null;
  }
  return activeSpec.files.firstWhere((file) => file.isRequired).filename;
}

/// Builds an [InferenceModelSpec] for an installed model id.
Future<InferenceModelSpec?> buildInferenceModelSpec(
  String modelId, {
  LocalModelIdentityKv? identityKv,
}) async {
  final kv = identityKv ?? LocalModelIdentityKv();
  final repository = ServiceRegistry.instance.modelRepository;
  final info = await repository.loadModel(modelId);
  if (info == null) {
    return null;
  }

  final modelType = kv.readModelType(modelId);
  final fileType = kv.readFileType(modelId);

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
    return null;
  }

  return InferenceModelSpec(
    name: displayNameFromFilename(modelId),
    modelSource: FileSource(filePath),
    modelType: modelType,
    fileType: fileType,
  );
}

/// Restores the persisted active model into Flutter Gemma.
Future<String?> ensurePersistedActiveLocalModel({
  LocalModelActiveKv? activeKv,
  LocalModelIdentityKv? identityKv,
}) {
  final existing = _restoreCompleter;
  if (existing != null) {
    return existing.future;
  }

  final completer = Completer<String?>();
  _restoreCompleter = completer;

  _restorePersistedActiveLocalModel(
    activeKv: activeKv ?? LocalModelActiveKv(),
    identityKv: identityKv ?? LocalModelIdentityKv(),
  ).then((id) {
    if (!completer.isCompleted) {
      completer.complete(id);
    }
  }).catchError((Object error, StackTrace stack) {
    if (!completer.isCompleted) {
      completer.completeError(error, stack);
    }
  }).whenComplete(() {
    _restoreCompleter = null;
  });

  return completer.future;
}

Future<String?> _restorePersistedActiveLocalModel({
  required LocalModelActiveKv activeKv,
  required LocalModelIdentityKv identityKv,
}) async {
  await ensureFlutterGemmaInitialized();
  final manager = FlutterGemmaPlugin.instance.modelManager;
  await manager.ensureInitialized();

  final persistedId = activeKv.read();
  if (persistedId == null) {
    return readActiveLocalModelIdFromManager();
  }

  final currentId = readActiveLocalModelIdFromManager();
  if (currentId == persistedId && FlutterGemma.hasActiveModel()) {
    return persistedId;
  }

  final spec = await buildInferenceModelSpec(
    persistedId,
    identityKv: identityKv,
  );
  if (spec == null) {
    activeKv.clear();
    log(
      'Persisted active model missing on disk — cleared selection: $persistedId',
      name: _logName,
    );
    return null;
  }

  await manager.ensureModelReadyFromSpec(spec);
  log('Restored active local model: $persistedId', name: _logName);
  return persistedId;
}

/// Selects a model, persists the choice, and registers it with Flutter Gemma.
Future<void> activateLocalModel(
  String modelId, {
  LocalModelActiveKv? activeKv,
  LocalModelIdentityKv? identityKv,
}) async {
  await ensureFlutterGemmaInitialized();
  final spec = await buildInferenceModelSpec(
    modelId,
    identityKv: identityKv ?? LocalModelIdentityKv(),
  );
  if (spec == null) {
    throw StateError('Model not found or missing on disk: $modelId');
  }

  final manager = FlutterGemmaPlugin.instance.modelManager;
  await manager.ensureModelReadyFromSpec(spec);
  (activeKv ?? LocalModelActiveKv()).write(modelId);
  log('Active local model saved: $modelId', name: _logName);
}

/// Loads the persisted active model and returns shared runtime context.
Future<ActiveLocalModelContext?> resolveActiveLocalModelContext({
  bool restorePersisted = true,
  LocalModelActiveKv? activeKv,
  LocalModelIdentityKv? identityKv,
}) async {
  if (restorePersisted) {
    await ensurePersistedActiveLocalModel(
      activeKv: activeKv,
      identityKv: identityKv,
    );
  } else {
    await ensureFlutterGemmaInitialized();
    final manager = FlutterGemmaPlugin.instance.modelManager;
    await manager.ensureInitialized();
  }

  if (!FlutterGemma.hasActiveModel()) {
    return null;
  }

  final spec = FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
  if (spec is! InferenceModelSpec) {
    return null;
  }

  if (spec.fileType == ModelFileType.litertlm) {
    await ensureLitertLmRuntimeSupported();
  }

  final modelId = spec.files.firstWhere((file) => file.isRequired).filename;
  return ActiveLocalModelContext(
    modelId: modelId,
    spec: spec,
    inferenceConfig: readLocalModelInferenceConfig(modelId),
  );
}

/// Opens the active [InferenceModel] using shared per-model inference settings.
Future<InferenceModel> openActiveInferenceModel(
  ActiveLocalModelContext context,
) async {
  return FlutterGemma.getActiveModel(
    maxTokens: context.inferenceConfig.maxTokens,
    preferredBackend: await preferredLitertBackend(),
  );
}

/// Creates a chat session from shared active-model context.
Future<InferenceChat> openActiveInferenceChat({
  required InferenceModel model,
  required ActiveLocalModelContext context,
}) {
  final config = context.inferenceConfig;
  return model.createChat(
    modelType: context.modelType,
    temperature: config.temperature,
    topK: config.topK,
    topP: config.topP,
    randomSeed: config.randomSeed,
    tokenBuffer: config.tokenBuffer,
  );
}

/// Clears Flutter Gemma's in-memory active model reference without deleting
/// installed model files or the app's persisted active-model selection.
Future<void> clearActiveLocalModelRuntime({
  ModelFileManager? modelManager,
}) async {
  if (modelManager == null) {
    await ensureFlutterGemmaInitialized();
  }
  final manager = modelManager ?? FlutterGemmaPlugin.instance.modelManager;
  await manager.ensureInitialized();
  await manager.clearModelCache();
}
