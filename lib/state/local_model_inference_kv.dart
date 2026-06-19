import 'dart:async';
import 'dart:convert';

import 'package:nitmgpt/core/realm_kv.dart';
import 'package:signals/signals.dart';

/// Defaults tuned for on-device inference (chat + notification classification).
class LocalModelInferenceConfig {
  const LocalModelInferenceConfig({
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

  static const defaults = LocalModelInferenceConfig(
    maxTokens: 256,
    temperature: 0.2,
    topK: 1,
    topP: 0.95,
    randomSeed: 1,
    tokenBuffer: 128,
  );

  LocalModelInferenceConfig copyWith({
    int? maxTokens,
    double? temperature,
    int? topK,
    double? topP,
    int? randomSeed,
    int? tokenBuffer,
  }) {
    return LocalModelInferenceConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      randomSeed: randomSeed ?? this.randomSeed,
      tokenBuffer: tokenBuffer ?? this.tokenBuffer,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxTokens': maxTokens,
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'randomSeed': randomSeed,
        'tokenBuffer': tokenBuffer,
      };

  factory LocalModelInferenceConfig.fromJson(Map<String, dynamic> json) {
    return LocalModelInferenceConfig(
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

const localModelInferenceStoreKey = 'nitmgpt_local_model_inference_configs';

/// Reads per-model inference params from Realm KV (UI and background service).
LocalModelInferenceConfig readLocalModelInferenceConfig(String modelId) {
  final raw = readKvString(localModelInferenceStoreKey);
  if (raw == null || raw.isEmpty) {
    return LocalModelInferenceConfig.defaults;
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return LocalModelInferenceConfig.defaults;
    }

    final entry = decoded[modelId];
    if (entry is! Map) {
      return LocalModelInferenceConfig.defaults;
    }

    return LocalModelInferenceConfig.fromJson(
      Map<String, dynamic>.from(entry),
    );
  } catch (_) {
    return LocalModelInferenceConfig.defaults;
  }
}

/// Per-model inference parameters persisted in Realm KV.
class LocalModelInferenceKv {
  static const _storeKey = localModelInferenceStoreKey;

  Map<String, LocalModelInferenceConfig>? _cache;
  final revision = signal(0);

  LocalModelInferenceConfig read(String modelId) {
    _ensureLoaded();
    return _cache![modelId] ?? readLocalModelInferenceConfig(modelId);
  }

  void write(String modelId, LocalModelInferenceConfig config) {
    _ensureLoaded();
    _cache![modelId] = config;
    revision.value++;
    unawaited(_persist());
  }

  Future<void> remove(String modelId) async {
    _ensureLoaded();
    _cache!.remove(modelId);
    revision.value++;
    await _persist();
  }

  void resetToDefaults(String modelId) {
    write(modelId, LocalModelInferenceConfig.defaults);
  }

  void _ensureLoaded() {
    _cache ??= _loadFromKv();
  }

  Map<String, LocalModelInferenceConfig> _loadFromKv() {
    final raw = readKvString(_storeKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return {};
      }

      final result = <String, LocalModelInferenceConfig>{};
      decoded.forEach((key, value) {
        if (key is! String || value is! Map) return;
        result[key] = LocalModelInferenceConfig.fromJson(
          Map<String, dynamic>.from(value),
        );
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist() async {
    final encoded = <String, dynamic>{
      for (final entry in _cache!.entries) entry.key: entry.value.toJson(),
    };
    await writeKvStringAsync(_storeKey, jsonEncode(encoded));
  }
}
