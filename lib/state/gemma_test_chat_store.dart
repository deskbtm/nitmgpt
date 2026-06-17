import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/platform/litert_backend.dart';
import 'package:nitmgpt/state/gemma_model_helpers.dart';
import 'package:signals_flutter/signals_flutter.dart';

class GemmaChatBubble {
  const GemmaChatBubble({
    required this.text,
    required this.isUser,
    this.isThinking = false,
  });

  final String text;
  final bool isUser;
  final bool isThinking;
}

class GemmaTestChatStore {
  final isInitializing = signal(true);
  final isGenerating = signal(false);
  final errorMessage = signal<String?>(null);
  final modelLabel = signal<String?>(null);
  final messages = listSignal<GemmaChatBubble>([]);

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _disposed = false;

  bool get isReady => _chat != null && !isInitializing.value;

  Future<void> init() async {
    isInitializing.value = true;
    errorMessage.value = null;

    if (!FlutterGemma.hasActiveModel()) {
      isInitializing.value = false;
      errorMessage.value = 'No active model for chat';
      return;
    }

    try {
      final activeSpec =
          FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
      if (activeSpec is InferenceModelSpec) {
        modelLabel.value = displayNameFromFilename(
          activeSpec.files.firstWhere((f) => f.isRequired).filename,
        );
      }

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: await preferredLitertBackend(),
      );
      final chat = await model.createChat(
        modelType: activeSpec is InferenceModelSpec
            ? activeSpec.modelType
            : ModelType.general,
      );

      if (_disposed) {
        await chat.close();
        await model.close();
        return;
      }

      _model = model;
      _chat = chat;
      isInitializing.value = false;
      errorMessage.value = null;
    } catch (_) {
      if (_disposed) return;
      isInitializing.value = false;
      errorMessage.value = 'Failed to load model';
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _disposeRuntime();
  }

  Future<void> clearChat() async {
    if (isGenerating.value) return;
    await _disposeRuntime();
    if (_disposed) return;
    messages.value = [];
    isInitializing.value = true;
    errorMessage.value = null;
    await init();
  }

  Future<void> stopGeneration() async {
    await _chat?.stopGeneration();
    if (_disposed) return;
    isGenerating.value = false;
  }

  Future<void> sendMessage(String text) async {
    final chat = _chat;
    if (chat == null || isGenerating.value) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    isGenerating.value = true;
    errorMessage.value = null;
    messages.value = [
      ...messages.value,
      GemmaChatBubble(text: trimmed, isUser: true),
      const GemmaChatBubble(text: '', isUser: false),
    ];

    try {
      await chat.addQuery(Message.text(text: trimmed, isUser: true));

      var assistantIndex = messages.value.length - 1;
      final buffer = StringBuffer();

      await for (final response in chat.generateChatResponseAsync()) {
        if (_disposed) return;

        if (response is TextResponse) {
          buffer.write(response.token);
          _replaceMessageAt(
            assistantIndex,
            GemmaChatBubble(text: buffer.toString(), isUser: false),
          );
        } else if (response is ThinkingResponse) {
          final current = [...messages.value];
          current.insert(
            assistantIndex,
            GemmaChatBubble(
              text: response.content,
              isUser: false,
              isThinking: true,
            ),
          );
          messages.value = current;
          assistantIndex += 1;
        }
      }

      if (buffer.isEmpty && !_disposed) {
        final current = [...messages.value];
        if (current.isNotEmpty && !current.last.isUser) {
          current.removeLast();
          messages.value = current;
        }
      }
    } catch (error) {
      if (_disposed) return;
      errorMessage.value = error.toString();
      final current = [...messages.value];
      if (current.isNotEmpty && !current.last.isUser) {
        current.removeLast();
        messages.value = current;
      }
    } finally {
      if (!_disposed) {
        isGenerating.value = false;
      }
    }
  }

  void _replaceMessageAt(int index, GemmaChatBubble bubble) {
    final current = [...messages.value];
    if (index < 0 || index >= current.length) return;
    current[index] = bubble;
    messages.value = current;
  }

  Future<void> _disposeRuntime() async {
    try {
      await _chat?.close();
    } catch (_) {}
    try {
      await _model?.close();
    } catch (_) {}
    _chat = null;
    _model = null;
  }
}
