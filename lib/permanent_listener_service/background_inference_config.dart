import 'dart:convert';

import 'package:nitmgpt/core/realm_kv.dart';

const inferenceConfigStoreKey = 'nitmgpt_local_model_inference_configs';

/// Mirrors [LocalModelInferenceConfig] JSON stored by the settings UI.
class BackgroundInferenceConfig {
  const BackgroundInferenceConfig({
    required this.maxTokens,
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.randomSeed,
    required this.tokenBuffer,
  });

  final int maxTokens;
  final double temperature;
  final int topK;
  final double topP;
  final int randomSeed;
  final int tokenBuffer;

  static const defaults = BackgroundInferenceConfig(
    maxTokens: 256,
    temperature: 0.2,
    topK: 1,
    topP: 0.95,
    randomSeed: 1,
    tokenBuffer: 128,
  );

  factory BackgroundInferenceConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundInferenceConfig(
      maxTokens: (json['maxTokens'] as num?)?.round() ?? defaults.maxTokens,
      temperature:
          (json['temperature'] as num?)?.toDouble() ?? defaults.temperature,
      topK: (json['topK'] as num?)?.round() ?? defaults.topK,
      topP: (json['topP'] as num?)?.toDouble() ?? defaults.topP,
      randomSeed:
          (json['randomSeed'] as num?)?.round() ?? defaults.randomSeed,
      tokenBuffer:
          (json['tokenBuffer'] as num?)?.round() ?? defaults.tokenBuffer,
    );
  }
}

BackgroundInferenceConfig readBackgroundInferenceConfig(String modelId) {
  final raw = readKvString(inferenceConfigStoreKey);
  if (raw == null || raw.isEmpty) {
    return BackgroundInferenceConfig.defaults;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return BackgroundInferenceConfig.defaults;
    }

    final entry = decoded[modelId];
    if (entry is! Map) {
      return BackgroundInferenceConfig.defaults;
    }

    return BackgroundInferenceConfig.fromJson(
      Map<String, dynamic>.from(entry),
    );
  } catch (_) {
    return BackgroundInferenceConfig.defaults;
  }
}
