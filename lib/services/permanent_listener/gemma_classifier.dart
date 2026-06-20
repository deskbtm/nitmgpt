import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:nitmgpt/services/permanent_listener/background_rules.dart';
import 'package:nitmgpt/services/permanent_listener/gpt_response.dart';
import 'package:nitmgpt/services/permanent_listener/permanent_listener_actions.dart';
import 'package:nitmgpt/services/active_local_model_resolver.dart';
import 'package:nitmgpt/utils/json.dart';

/// On-device notification classifier for the permanent listener background service.
class PermanentListenerGemmaClassifier {
  InferenceModel? _model;
  ActiveLocalModelContext? _context;
  bool _ready = false;

  /// Second line of defense: serializes Gemma inference even if classify is
  /// invoked outside [enqueuePermanentListenerNotification].
  Future<void> _inferenceQueue = Future<void>.value();

  bool get isReady => _ready;

  Future<void> init() => _loadActiveModel();

  Future<void> reload() => _loadActiveModel();

  Future<void> dispose() async {
    try {
      await _model?.close();
    } catch (_) {}
    _model = null;
    _context = null;
    _ready = false;
  }

  Future<void> _loadActiveModel() async {
    await dispose();

    final context = await resolveActiveLocalModelContext();
    if (context == null) {
      logPermanentListener(
        'No active local model — skip notification classification',
      );
      return;
    }

    _model = await openActiveInferenceModel(context);
    _context = context;
    _ready = true;

    logPermanentListener('Gemma classifier ready: ${context.modelId}');
  }

  Future<GPTResponse?> classifyNotification({
    required String notificationText,
    required Settings settings,
  }) {
    return _enqueue(
      () => _classifyNotificationImpl(
        notificationText: notificationText,
        settings: settings,
      ),
    );
  }

  Future<GPTResponse?> _enqueue(Future<GPTResponse?> Function() task) {
    final completer = Completer<GPTResponse?>();
    // Chain onto the previous inference so only one chat session runs at a time.
    _inferenceQueue = _inferenceQueue.then((_) async {
      if (completer.isCompleted) {
        return;
      }
      try {
        completer.complete(await task());
      } catch (error, stackTrace) {
        logPermanentListener('$error', stackTrace: stackTrace);
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
    final model = _model;
    final context = _context;
    if (!_ready || model == null || context == null) {
      return null;
    }

    final prompt = buildClassificationPrompt(
      notificationText,
      formatFieldDefinitions(settings),
    );
    logPermanentListener(prompt);

    InferenceChat? chat;
    try {
      chat = await openActiveInferenceChat(model: model, context: context);
      await chat.addQuery(Message.text(text: prompt, isUser: true));

      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
        }
      }

      final raw = normalizeAssistantStreamText(buffer.toString());
      if (raw.isEmpty) {
        logPermanentListener('Model returned empty classification');
        return null;
      }

      logPermanentListener('Model raw classification: $raw');

      final json = looseJSONParse(raw);
      if (json is! Map<String, dynamic>) {
        logPermanentListener('Model returned non-JSON classification: $raw');
        return null;
      }

      final result = GPTResponse.fromJson(json);
      logPermanentListener(
        'Model classification parsed: isAd=${result.isAd} adProb=${result.adProbability} '
        'isSpam=${result.isSpam} spamProb=${result.spamProbability}',
      );
      return result;
    } finally {
      try {
        await chat?.close();
      } catch (_) {}
    }
  }
}
