import 'dart:async';
import 'dart:developer';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/permanent_listener_service/background_inference_config.dart';
import 'package:nitmgpt/permanent_listener_service/background_rules.dart';
import 'package:nitmgpt/permanent_listener_service/gpt_response.dart';
import 'package:nitmgpt/permanent_listener_service/json_utils.dart';
import 'package:nitmgpt/platform/litert_backend.dart';

/// On-device notification classifier for the background worker isolate.
class PermanentListenerGemmaClassifier {
  InferenceModel? _model;
  ModelType _modelType = ModelType.general;
  String? _activeModelId;
  BackgroundInferenceConfig _config = BackgroundInferenceConfig.defaults;
  bool _ready = false;

  Future<void> _inferenceQueue = Future<void>.value();

  bool get isReady => _ready;

  Future<void> init() async {
    await _loadActiveModel();
  }

  Future<void> reload() => _loadActiveModel();

  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
    _ready = false;
    _activeModelId = null;
  }

  Future<void> _loadActiveModel() async {
    await dispose();
    await ensureFlutterGemmaInitialized();

    final manager = FlutterGemmaPlugin.instance.modelManager;
    await manager.ensureInitialized();

    if (!FlutterGemma.hasActiveModel()) {
      log(
        'No active local model — skip notification classification',
        name: 'permanent_listener_service',
      );
      return;
    }

    final activeSpec = manager.activeInferenceModel;
    if (activeSpec is! InferenceModelSpec) {
      log(
        'Active model spec is not inference — skip classification',
        name: 'permanent_listener_service',
      );
      return;
    }

    _activeModelId =
        activeSpec.files.firstWhere((file) => file.isRequired).filename;
    _modelType = activeSpec.modelType;

    if (activeSpec.fileType == ModelFileType.litertlm) {
      await ensureLitertLmRuntimeSupported();
    }

    _config = readBackgroundInferenceConfig(_activeModelId!);

    _model = await FlutterGemma.getActiveModel(
      maxTokens: _config.maxTokens,
      preferredBackend: await preferredLitertBackend(),
    );
    _ready = true;

    log(
      'Gemma classifier ready: $_activeModelId',
      name: 'permanent_listener_service',
    );
  }

  Future<GPTResponse?> classifyNotification({
    required String notificationText,
    required Settings settings,
  }) {
    final completer = Completer<GPTResponse?>();
    _inferenceQueue = _inferenceQueue.then((_) async {
      if (completer.isCompleted) return;
      try {
        completer.complete(
          await _classifyNotificationImpl(
            notificationText: notificationText,
            settings: settings,
          ),
        );
      } catch (error, stackTrace) {
        log(
          '$error',
          name: 'permanent_listener_service',
          stackTrace: stackTrace,
        );
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      }
    });
    return completer.future;
  }

  Future<GPTResponse?> _classifyNotificationImpl({
    required String notificationText,
    required Settings settings,
  }) async {
    if (!_ready || _model == null) {
      return null;
    }

    final prompt = buildClassificationPrompt(
      notificationText,
      formatFieldDefinitions(settings),
    );
    log(prompt, name: 'permanent_listener_service');

    InferenceChat? chat;
    try {
      chat = await _model!.createChat(
        modelType: _modelType,
        temperature: _config.temperature,
        topK: _config.topK,
        topP: _config.topP,
        randomSeed: _config.randomSeed,
        tokenBuffer: _config.tokenBuffer,
      );

      await chat.addQuery(Message.text(text: prompt, isUser: true));

      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
        }
      }

      final raw = normalizeAssistantStreamText(buffer.toString());
      if (raw.isEmpty) {
        return null;
      }

      final json = looseJSONParse(raw);
      if (json is! Map<String, dynamic>) {
        log(
          'Model returned non-JSON classification: $raw',
          name: 'permanent_listener_service',
        );
        return null;
      }

      return GPTResponse.fromJson(json);
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }
}
