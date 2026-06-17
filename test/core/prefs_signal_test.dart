import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/core/prefs_signal.dart';
import 'package:nitmgpt/state/gemma_model_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initAppPrefs();
  });

  group('PrefStringSignal', () {
    test('persists value changes', () async {
      final signal = prefString('test_key', defaultValue: 'fallback');

      expect(signal.value, 'fallback');

      signal.value = 'saved';
      await Future<void>.delayed(Duration.zero);

      expect(requireAppPrefs().getString('test_key'), 'saved');

      final reloaded = prefString('test_key', defaultValue: 'fallback');
      expect(reloaded.value, 'saved');
    });

    test('removes key when empty and storeNullAsRemove is true', () async {
      final signal = prefString('clearable_key', defaultValue: 'keep');

      signal.value = 'temp';
      await Future<void>.delayed(Duration.zero);
      signal.value = '';
      await Future<void>.delayed(Duration.zero);

      expect(requireAppPrefs().containsKey('clearable_key'), isFalse);
    });
  });

  group('GemmaModelIdentityPrefs', () {
    test('writes and reads model identity', () async {
      final prefs = GemmaModelIdentityPrefs();

      await prefs.write(
        id: 'gemma-3-270m.task',
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      );

      expect(prefs.readModelType('gemma-3-270m.task'), ModelType.gemmaIt);
      expect(prefs.readFileType('gemma-3-270m.task'), ModelFileType.task);
    });

    test('remove clears stored identity', () async {
      final prefs = GemmaModelIdentityPrefs();

      await prefs.write(
        id: 'model.litertlm',
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      );
      await prefs.remove('model.litertlm');

      expect(prefs.readModelType('model.litertlm'), ModelType.general);
      expect(
        prefs.readFileType('model.litertlm'),
        ModelFileType.litertlm,
      );
    });
  });
}
