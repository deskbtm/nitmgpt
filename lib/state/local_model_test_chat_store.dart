import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:nitmgpt/core/gemma_bootstrap.dart';
import 'package:nitmgpt/core/safe_signal_write.dart';
import 'package:nitmgpt/platform/litert_backend.dart';
import 'package:nitmgpt/state/local_model_inference_prefs.dart';
import 'package:nitmgpt/state/local_model_helpers.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ChatBubble {
  const ChatBubble({
    required this.text,
    required this.isUser,
    this.isThinking = false,
  });

  final String text;
  final bool isUser;
  final bool isThinking;
}

class LocalModelTestChatStore {
  LocalModelTestChatStore({required this.inferencePrefs});

  final LocalModelInferencePrefs inferencePrefs;
  final isInitializing = signal(true);
  final isGenerating = signal(false);
  final errorMessage = signal<String?>(null);
  final modelLabel = signal<String?>(null);
  final messages = listSignal<ChatBubble>([]);

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _disposed = false;

  bool get isReady => _chat != null && !isInitializing.value;

  Future<void> init() async {
    safeSignalWrite(() {
      isInitializing.value = true;
      errorMessage.value = null;
    });

    try {
      await ensureFlutterGemmaInitialized();
      if (!FlutterGemma.hasActiveModel()) {
        safeSignalWrite(() {
          isInitializing.value = false;
          errorMessage.value = 'No active model for chat';
        });
        return;
      }

      final activeSpec =
          FlutterGemmaPlugin.instance.modelManager.activeInferenceModel;
      if (activeSpec is InferenceModelSpec &&
          activeSpec.fileType == ModelFileType.litertlm) {
        await ensureLitertLmRuntimeSupported();
      }

      String? activeModelId;
      if (activeSpec is InferenceModelSpec) {
        activeModelId =
            activeSpec.files.firstWhere((f) => f.isRequired).filename;
        final label = displayNameFromFilename(activeModelId);
        safeSignalWrite(() => modelLabel.value = label);
      }

      final config = activeModelId == null
          ? LocalModelInferenceConfig.defaults
          : inferencePrefs.read(activeModelId);

      final model = await FlutterGemma.getActiveModel(
        maxTokens: config.maxTokens,
        preferredBackend: await preferredLitertBackend(),
      );
      final chat = await model.createChat(
        modelType: activeSpec is InferenceModelSpec
            ? activeSpec.modelType
            : ModelType.general,
        temperature: config.temperature,
        topK: config.topK,
        topP: config.topP,
        randomSeed: config.randomSeed,
        tokenBuffer: config.tokenBuffer,
      );

      if (_disposed) {
        await chat.close();
        await model.close();
        return;
      }

      _model = model;
      _chat = chat;
      safeSignalWrite(() {
        isInitializing.value = false;
        errorMessage.value = null;
      });
    } catch (error) {
      if (_disposed) return;
      final message = error is UnsupportedError &&
              error.message == kLitertLmEmulatorUnsupportedKey
          ? kLitertLmEmulatorUnsupportedKey
          : 'Failed to load model';
      safeSignalWrite(() {
        isInitializing.value = false;
        errorMessage.value = message;
      });
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _disposeRuntime();
  }

  Future<void> clearChat() async {
    if (isGenerating.value) return;
    await reloadForActiveModel();
  }

  Future<void> reloadForActiveModel() async {
    if (isGenerating.value) return;
    await _disposeRuntime();
    if (_disposed) return;
    safeSignalWrite(() {
      messages.value = [];
      isInitializing.value = true;
      errorMessage.value = null;
      modelLabel.value = null;
    });
    await init();
  }

  Future<void> stopGeneration() async {
    await _chat?.stopGeneration();
    if (_disposed) return;
    safeSignalWrite(() => isGenerating.value = false);
  }

  Future<void> sendMessage(String text) async {
    final chat = _chat;
    if (chat == null || isGenerating.value) return;

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    safeSignalWrite(() {
      isGenerating.value = true;
      errorMessage.value = null;
      messages.value = [
        ...messages.value,
        ChatBubble(text: trimmed, isUser: true),
      ];
    });

    try {
      await chat.addQuery(Message.text(text: trimmed, isUser: true));

      int? assistantIndex;
      final buffer = StringBuffer();

      await for (final response in chat.generateChatResponseAsync()) {
        if (_disposed) return;

        if (response is TextResponse) {
          buffer.write(response.token);
          final text = normalizeAssistantStreamText(buffer.toString());
          if (text.isEmpty) continue;
          if (assistantIndex == null) {
            final nextIndex = messages.value.length;
            safeSignalWrite(() {
              messages.value = [
                ...messages.value,
                ChatBubble(text: text, isUser: false),
              ];
            });
            assistantIndex = nextIndex;
          } else {
            _replaceMessageAt(
              assistantIndex,
              ChatBubble(text: text, isUser: false),
            );
          }
        } else if (response is ThinkingResponse) {
          final hadAssistant = assistantIndex != null;
          safeSignalWrite(() {
            final current = [...messages.value];
            final insertAt = assistantIndex ?? current.length;
            current.insert(
              insertAt,
              ChatBubble(
                text: response.content,
                isUser: false,
                isThinking: true,
              ),
            );
            messages.value = current;
          });
          if (hadAssistant) {
            assistantIndex = assistantIndex + 1;
          }
        }
      }

      if (buffer.isEmpty && assistantIndex != null && !_disposed) {
        final idx = assistantIndex;
        safeSignalWrite(() {
          final current = [...messages.value];
          if (idx < current.length &&
              !current[idx].isUser &&
              !current[idx].isThinking) {
            current.removeAt(idx);
            messages.value = current;
          }
        });
      }
    } catch (error) {
      if (_disposed) return;
      safeSignalWrite(() {
        errorMessage.value = error.toString();
        final current = [...messages.value];
        if (current.isNotEmpty &&
            !current.last.isUser &&
            !current.last.isThinking &&
            current.last.text.isEmpty) {
          current.removeLast();
          messages.value = current;
        }
      });
    } finally {
      if (!_disposed) {
        safeSignalWrite(() => isGenerating.value = false);
      }
    }
  }

  void _replaceMessageAt(int index, ChatBubble bubble) {
    safeSignalWrite(() {
      final current = [...messages.value];
      if (index < 0 || index >= current.length) return;
      current[index] = bubble;
      messages.value = current;
    });
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
