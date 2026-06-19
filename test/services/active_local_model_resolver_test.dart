import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitmgpt/services/active_local_model_resolver.dart';

void main() {
  group('clearActiveLocalModelRuntime', () {
    test('clears the active flutter_gemma model cache', () async {
      final manager = _FakeModelFileManager();

      await clearActiveLocalModelRuntime(modelManager: manager);

      expect(manager.ensureInitializedCalls, 1);
      expect(manager.clearModelCacheCalls, 1);
    });
  });
}

class _FakeModelFileManager implements ModelFileManager {
  var ensureInitializedCalls = 0;
  var clearModelCacheCalls = 0;

  @override
  Future<void> ensureInitialized() async {
    ensureInitializedCalls += 1;
  }

  @override
  Future<void> clearModelCache() async {
    clearModelCacheCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
