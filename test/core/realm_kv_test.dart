import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/core/realm_kv.dart';
import 'package:nitmgpt/core/realm_signal.dart';
import 'package:nitmgpt/models/kv_entry.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/state/local_model_identity_kv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    realm.write(() {
      realm.deleteAll<KvEntry>();
    });
  });

  group('KvStringSignal', () {
    test('persists value changes', () {
      final signal = kvString('test_key', defaultValue: 'fallback');

      expect(signal.value, 'fallback');

      signal.value = 'saved';

      expect(readKvString('test_key'), 'saved');

      final reloaded = kvString('test_key', defaultValue: 'fallback');
      expect(reloaded.value, 'saved');
    });

    test('removes key when empty and storeEmptyAsRemove is true', () {
      final signal = kvString('clearable_key', defaultValue: 'keep');

      signal.value = 'temp';
      signal.value = '';

      expect(hasKvKey('clearable_key'), isFalse);
    });
  });

  group('LocalModelIdentityKv', () {
    test('writes and reads model identity', () {
      final kv = LocalModelIdentityKv();

      kv.write(
        id: 'gemma-3-270m.task',
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
      );

      expect(kv.readModelType('gemma-3-270m.task'), ModelType.gemmaIt);
      expect(kv.readFileType('gemma-3-270m.task'), ModelFileType.task);
    });

    test('remove clears stored identity', () {
      final kv = LocalModelIdentityKv();

      kv.write(
        id: 'model.litertlm',
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      );
      kv.remove('model.litertlm');

      expect(kv.readModelType('model.litertlm'), ModelType.general);
      expect(
        kv.readFileType('model.litertlm'),
        ModelFileType.litertlm,
      );
    });
  });
}
