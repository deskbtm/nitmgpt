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
