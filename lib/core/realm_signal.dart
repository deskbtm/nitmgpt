import 'dart:async';

import 'package:nitmgpt/core/realm_kv.dart';
import 'package:nitmgpt/models/realm.dart';
import 'package:nitmgpt/models/settings.dart';
import 'package:signals/signals.dart';

/// Realm-backed persistence, mirroring signals_core [PersistedSignalMixin].
///
/// See: https://dartsignals.dev/guides/persisted-signals/
mixin RealmPersistedSignalMixin<T> on Signal<T> {
  Settings get settings;

  T readFrom(Settings settings);

  void writeTo(Settings settings, T value);

  bool get asyncWrite => false;

  bool _hydrated = false;

  /// Loads the current Realm value into the signal without persisting.
  void hydrateFromRealm() {
    super.value = readFrom(settings);
    _hydrated = true;
  }

  @override
  set value(T value) {
    super.value = value;
    if (!_hydrated) return;
    _persist(value);
  }

  void _persist(T value) {
    if (asyncWrite) {
      realm.writeAsync(() => writeTo(settings, value));
    } else {
      realm.write(() => writeTo(settings, value));
    }
  }
}

class RealmStringSignal extends Signal<String> with RealmPersistedSignalMixin<String> {
  RealmStringSignal({
    required Settings settings,
    required String? Function(Settings s) read,
    required void Function(Settings s, String? value) write,
    String defaultValue = '',
    bool asyncWrite = false,
  })  : _settings = settings,
        _readNullable = read,
        _writeNullable = write,
        _asyncWrite = asyncWrite,
        super(read(settings) ?? defaultValue) {
    hydrateFromRealm();
  }

  final Settings _settings;
  final String? Function(Settings s) _readNullable;
  final void Function(Settings s, String? value) _writeNullable;
  final bool _asyncWrite;

  @override
  Settings get settings => _settings;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  String readFrom(Settings settings) => _readNullable(settings) ?? '';

  @override
  void writeTo(Settings settings, String value) {
    _writeNullable(settings, value.isEmpty ? null : value);
  }
}

class RealmBoolSignal extends Signal<bool> with RealmPersistedSignalMixin<bool> {
  RealmBoolSignal({
    required Settings settings,
    required bool Function(Settings s) read,
    required void Function(Settings s, bool value) write,
    bool asyncWrite = false,
  })  : _settings = settings,
        _read = read,
        _write = write,
        _asyncWrite = asyncWrite,
        super(read(settings)) {
    hydrateFromRealm();
  }

  final Settings _settings;
  final bool Function(Settings s) _read;
  final void Function(Settings s, bool value) _write;
  final bool _asyncWrite;

  @override
  Settings get settings => _settings;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  bool readFrom(Settings settings) => _read(settings);

  @override
  void writeTo(Settings settings, bool value) => _write(settings, value);
}

class RealmIntSignal extends Signal<int> with RealmPersistedSignalMixin<int> {
  RealmIntSignal({
    required Settings settings,
    required int Function(Settings s) read,
    required void Function(Settings s, int value) write,
    bool asyncWrite = false,
  })  : _settings = settings,
        _read = read,
        _write = write,
        _asyncWrite = asyncWrite,
        super(read(settings)) {
    hydrateFromRealm();
  }

  final Settings _settings;
  final int Function(Settings s) _read;
  final void Function(Settings s, int value) _write;
  final bool _asyncWrite;

  @override
  Settings get settings => _settings;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  int readFrom(Settings settings) => _read(settings);

  @override
  void writeTo(Settings settings, int value) => _write(settings, value);
}

RealmStringSignal realmString(
  Settings settings,
  String? Function(Settings s) read,
  void Function(Settings s, String? value) write, {
  String defaultValue = '',
}) {
  return RealmStringSignal(
    settings: settings,
    read: read,
    write: write,
    defaultValue: defaultValue,
  );
}

RealmBoolSignal realmBool(
  Settings settings,
  bool Function(Settings s) read,
  void Function(Settings s, bool value) write, {
  bool asyncWrite = false,
}) {
  return RealmBoolSignal(
    settings: settings,
    read: read,
    write: write,
    asyncWrite: asyncWrite,
  );
}

RealmIntSignal realmInt(
  Settings settings,
  int Function(Settings s) read,
  void Function(Settings s, int value) write, {
  bool asyncWrite = false,
}) {
  return RealmIntSignal(
    settings: settings,
    read: read,
    write: write,
    asyncWrite: asyncWrite,
  );
}

/// Realm [KvEntry]-backed persistence for arbitrary string keys.
mixin KvPersistedSignalMixin<T> on Signal<T> {
  String get key;

  T readFromKv();

  void writeToKv(T value);

  bool get asyncWrite => false;

  bool _hydrated = false;

  void hydrateFromKv() {
    super.value = readFromKv();
    _hydrated = true;
  }

  @override
  set value(T value) {
    super.value = value;
    if (!_hydrated) return;
    _persist(value);
  }

  void _persist(T value) {
    if (asyncWrite) {
      unawaited(_persistAsync(value));
    } else {
      writeToKv(value);
    }
  }

  Future<void> _persistAsync(T value) async {
    if (value is String) {
      await writeKvStringAsync(key, value);
      return;
    }
    writeToKv(value);
  }
}

class KvStringSignal extends Signal<String> with KvPersistedSignalMixin<String> {
  KvStringSignal({
    required String kvKey,
    String defaultValue = '',
    bool storeEmptyAsRemove = true,
    bool asyncWrite = false,
  })  : _key = kvKey,
        _defaultValue = defaultValue,
        _storeEmptyAsRemove = storeEmptyAsRemove,
        _asyncWrite = asyncWrite,
        super(readKvString(kvKey) ?? defaultValue) {
    hydrateFromKv();
  }

  final String _key;
  final String _defaultValue;
  final bool _storeEmptyAsRemove;
  final bool _asyncWrite;

  @override
  String get key => _key;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  String readFromKv() => readKvString(_key) ?? _defaultValue;

  @override
  void writeToKv(String value) {
    if (_storeEmptyAsRemove && value.isEmpty) {
      removeKvKey(_key);
      return;
    }
    writeKvString(_key, value);
  }
}

class KvBoolSignal extends Signal<bool> with KvPersistedSignalMixin<bool> {
  KvBoolSignal({
    required String kvKey,
    bool defaultValue = false,
    bool asyncWrite = false,
  })  : _key = kvKey,
        _defaultValue = defaultValue,
        _asyncWrite = asyncWrite,
        super(readKvBool(kvKey, defaultValue: defaultValue)) {
    hydrateFromKv();
  }

  final String _key;
  final bool _defaultValue;
  final bool _asyncWrite;

  @override
  String get key => _key;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  bool readFromKv() => readKvBool(_key, defaultValue: _defaultValue);

  @override
  void writeToKv(bool value) => writeKvBool(_key, value);
}

class KvIntSignal extends Signal<int> with KvPersistedSignalMixin<int> {
  KvIntSignal({
    required String kvKey,
    int defaultValue = 0,
    bool asyncWrite = false,
  })  : _key = kvKey,
        _defaultValue = defaultValue,
        _asyncWrite = asyncWrite,
        super(readKvInt(kvKey, defaultValue: defaultValue)) {
    hydrateFromKv();
  }

  final String _key;
  final int _defaultValue;
  final bool _asyncWrite;

  @override
  String get key => _key;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  int readFromKv() => readKvInt(_key, defaultValue: _defaultValue);

  @override
  void writeToKv(int value) => writeKvInt(_key, value);
}

class KvDoubleSignal extends Signal<double> with KvPersistedSignalMixin<double> {
  KvDoubleSignal({
    required String kvKey,
    required double defaultValue,
    bool asyncWrite = false,
  })  : _key = kvKey,
        _defaultValue = defaultValue,
        _asyncWrite = asyncWrite,
        super(readKvDouble(kvKey, defaultValue: defaultValue)) {
    hydrateFromKv();
  }

  final String _key;
  final double _defaultValue;
  final bool _asyncWrite;

  @override
  String get key => _key;

  @override
  bool get asyncWrite => _asyncWrite;

  @override
  double readFromKv() => readKvDouble(_key, defaultValue: _defaultValue);

  @override
  void writeToKv(double value) => writeKvDouble(_key, value);
}

KvDoubleSignal kvDouble(
  String key, {
  required double defaultValue,
  bool asyncWrite = false,
}) {
  return KvDoubleSignal(
    kvKey: key,
    defaultValue: defaultValue,
    asyncWrite: asyncWrite,
  );
}

KvStringSignal kvString(
  String key, {
  String defaultValue = '',
  bool storeEmptyAsRemove = true,
  bool asyncWrite = false,
}) {
  return KvStringSignal(
    kvKey: key,
    defaultValue: defaultValue,
    storeEmptyAsRemove: storeEmptyAsRemove,
    asyncWrite: asyncWrite,
  );
}

KvBoolSignal kvBool(
  String key, {
  bool defaultValue = false,
  bool asyncWrite = false,
}) {
  return KvBoolSignal(
    kvKey: key,
    defaultValue: defaultValue,
    asyncWrite: asyncWrite,
  );
}

KvIntSignal kvInt(
  String key, {
  int defaultValue = 0,
  bool asyncWrite = false,
}) {
  return KvIntSignal(
    kvKey: key,
    defaultValue: defaultValue,
    asyncWrite: asyncWrite,
  );
}
