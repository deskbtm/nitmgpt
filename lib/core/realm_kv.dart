import 'package:nitmgpt/models/kv_entry.dart';
import 'package:nitmgpt/models/realm.dart';

KvEntry? _findKvEntry(String key) => realm.find<KvEntry>(key);

bool hasKvKey(String key) => _findKvEntry(key) != null;

void removeKvKey(String key) {
  final entry = _findKvEntry(key);
  if (entry == null) return;
  realm.write(() {
    realm.delete(entry);
  });
}

Future<void> removeKvKeyAsync(String key) async {
  final entry = _findKvEntry(key);
  if (entry == null) return;
  await realm.writeAsync(() {
    realm.delete(entry);
  });
}

String? readKvString(String key) => _findKvEntry(key)?.stringValue;

void writeKvString(String key, String value) {
  realm.write(() {
    _upsertKvEntry(key, stringValue: value);
  });
}

Future<void> writeKvStringAsync(String key, String value) async {
  await realm.writeAsync(() {
    _upsertKvEntry(key, stringValue: value);
  });
}

bool readKvBool(String key, {bool defaultValue = false}) {
  return _findKvEntry(key)?.boolValue ?? defaultValue;
}

void writeKvBool(String key, bool value) {
  realm.write(() {
    _upsertKvEntry(key, boolValue: value);
  });
}

int readKvInt(String key, {int defaultValue = 0}) {
  return _findKvEntry(key)?.intValue ?? defaultValue;
}

void writeKvInt(String key, int value) {
  realm.write(() {
    _upsertKvEntry(key, intValue: value);
  });
}

double readKvDouble(String key, {required double defaultValue}) {
  return _findKvEntry(key)?.doubleValue ?? defaultValue;
}

void writeKvDouble(String key, double value) {
  realm.write(() {
    _upsertKvEntry(key, doubleValue: value);
  });
}

void _upsertKvEntry(
  String key, {
  String? stringValue,
  bool? boolValue,
  int? intValue,
  double? doubleValue,
}) {
  final existing = realm.find<KvEntry>(key);
  if (existing != null) {
    if (stringValue != null) {
      existing.stringValue = stringValue;
    }
    if (boolValue != null) {
      existing.boolValue = boolValue;
    }
    if (intValue != null) {
      existing.intValue = intValue;
    }
    if (doubleValue != null) {
      existing.doubleValue = doubleValue;
    }
    return;
  }

  realm.add(
    KvEntry(
      key,
      stringValue: stringValue,
      boolValue: boolValue,
      intValue: intValue,
      doubleValue: doubleValue,
    ),
  );
}
