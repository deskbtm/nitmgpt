import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/state/local_model_inference_kv.dart';

void main() {
  group('LocalModelInferenceConfig', () {
    test('round-trips through json', () {
      const original = LocalModelInferenceConfig(
        maxTokens: 320,
        temperature: 0.35,
        topK: 4,
        topP: 0.88,
        randomSeed: 42,
        tokenBuffer: 200,
      );

      final restored = LocalModelInferenceConfig.fromJson(original.toJson());

      expect(restored.maxTokens, 320);
      expect(restored.temperature, 0.35);
      expect(restored.topK, 4);
      expect(restored.topP, 0.88);
      expect(restored.randomSeed, 42);
      expect(restored.tokenBuffer, 200);
    });

    test('falls back to defaults for missing json fields', () {
      final restored = LocalModelInferenceConfig.fromJson({});

      expect(restored.maxTokens, LocalModelInferenceConfig.defaults.maxTokens);
      expect(
        restored.temperature,
        LocalModelInferenceConfig.defaults.temperature,
      );
      expect(restored.topK, LocalModelInferenceConfig.defaults.topK);
    });

    test('copyWith overrides selected fields', () {
      const original = LocalModelInferenceConfig.defaults;
      final updated = original.copyWith(maxTokens: 512, temperature: 0.5);

      expect(updated.maxTokens, 512);
      expect(updated.temperature, 0.5);
      expect(updated.topK, original.topK);
    });
  });
}
