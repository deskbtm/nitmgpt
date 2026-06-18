import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:flutter_gemma_mediapipe/flutter_gemma_mediapipe.dart';
import 'package:nitmgpt/constants.dart';

Completer<void>? _gemmaInitCompleter;

/// Lazily initializes Flutter Gemma after first frame — not needed for home tab.
Future<void> ensureFlutterGemmaInitialized() {
  final existing = _gemmaInitCompleter;
  if (existing != null) return existing.future;

  final completer = Completer<void>();
  _gemmaInitCompleter = completer;

  FlutterGemma.initialize(
    huggingFaceToken: huggingFaceToken.isEmpty ? null : huggingFaceToken,
    inferenceEngines: const [
      LiteRtLmEngine(),
      MediaPipeEngine(),
    ],
  ).then((_) {
    if (!completer.isCompleted) completer.complete();
  }).catchError((Object error, StackTrace stack) {
    _gemmaInitCompleter = null;
    if (!completer.isCompleted) completer.completeError(error, stack);
  });

  return completer.future;
}
