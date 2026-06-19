import 'package:nitmgpt/core/realm_kv.dart';

/// Persists the user-selected local model id for notification filtering.
class LocalModelActiveKv {
  static const activeModelIdKey = 'nitmgpt_active_local_model_id';

  String? read() => readKvString(activeModelIdKey);

  void write(String modelId) => writeKvString(activeModelIdKey, modelId);

  void clear() => removeKvKey(activeModelIdKey);
}
