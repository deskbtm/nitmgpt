import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

SharedPreferences? _appPrefs;

/// Loads the process-wide [SharedPreferences] instance.
Future<void> initAppPrefs() async {
  _appPrefs ??= await SharedPreferences.getInstance();
}

/// Returns the initialized [SharedPreferences] instance.
SharedPreferences requireAppPrefs() {
  final prefs = _appPrefs;
  assert(
    prefs != null,
    'Call initAppPrefs() before accessing SharedPreferences-backed signals.',
  );
  return prefs!;
}

/// SharedPreferences-backed persistence, mirroring [RealmPersistedSignalMixin].
///
/// See: https://dartsignals.dev/guides/persisted-signals/
mixin PrefsPersistedSignalMixin<T> on Signal<T> {
  SharedPreferences get prefs;

  String get key;

  T readFrom(SharedPreferences prefs);

  Future<void> writeTo(SharedPreferences prefs, T value);

  bool _hydrated = false;

  /// Loads the current preference into the signal without persisting.
  void hydrateFromPrefs() {
    super.value = readFrom(prefs);
    _hydrated = true;
  }

  @override
  set value(T value) {
    super.value = value;
    if (!_hydrated) return;
    unawaited(writeTo(prefs, value));
  }
}

class PrefStringSignal extends Signal<String>
    with PrefsPersistedSignalMixin<String> {
  PrefStringSignal({
    required SharedPreferences prefs,
    required String prefKey,
    String defaultValue = '',
    bool storeNullAsRemove = true,
  })  : _prefs = prefs,
        _key = prefKey,
        _defaultValue = defaultValue,
        _storeNullAsRemove = storeNullAsRemove,
        super(prefs.getString(prefKey) ?? defaultValue) {
    hydrateFromPrefs();
  }

  final SharedPreferences _prefs;
  final String _key;
  final String _defaultValue;
  final bool _storeNullAsRemove;

  @override
  SharedPreferences get prefs => _prefs;

  @override
  String get key => _key;

  @override
  String readFrom(SharedPreferences prefs) =>
      prefs.getString(_key) ?? _defaultValue;

  @override
  Future<void> writeTo(SharedPreferences prefs, String value) async {
    if (_storeNullAsRemove && value.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, value);
  }
}

class PrefBoolSignal extends Signal<bool> with PrefsPersistedSignalMixin<bool> {
  PrefBoolSignal({
    required SharedPreferences prefs,
    required String prefKey,
    bool defaultValue = false,
  })  : _prefs = prefs,
        _key = prefKey,
        _defaultValue = defaultValue,
        super(prefs.getBool(prefKey) ?? defaultValue) {
    hydrateFromPrefs();
  }

  final SharedPreferences _prefs;
  final String _key;
  final bool _defaultValue;

  @override
  SharedPreferences get prefs => _prefs;

  @override
  String get key => _key;

  @override
  bool readFrom(SharedPreferences prefs) =>
      prefs.getBool(_key) ?? _defaultValue;

  @override
  Future<void> writeTo(SharedPreferences prefs, bool value) async {
    await prefs.setBool(_key, value);
  }
}

class PrefIntSignal extends Signal<int> with PrefsPersistedSignalMixin<int> {
  PrefIntSignal({
    required SharedPreferences prefs,
    required String prefKey,
    int defaultValue = 0,
  })  : _prefs = prefs,
        _key = prefKey,
        _defaultValue = defaultValue,
        super(prefs.getInt(prefKey) ?? defaultValue) {
    hydrateFromPrefs();
  }

  final SharedPreferences _prefs;
  final String _key;
  final int _defaultValue;

  @override
  SharedPreferences get prefs => _prefs;

  @override
  String get key => _key;

  @override
  int readFrom(SharedPreferences prefs) => prefs.getInt(_key) ?? _defaultValue;

  @override
  Future<void> writeTo(SharedPreferences prefs, int value) async {
    await prefs.setInt(_key, value);
  }
}

class PrefDoubleSignal extends Signal<double>
    with PrefsPersistedSignalMixin<double> {
  PrefDoubleSignal({
    required SharedPreferences prefs,
    required String prefKey,
    required double defaultValue,
  })  : _prefs = prefs,
        _key = prefKey,
        _defaultValue = defaultValue,
        super(prefs.getDouble(prefKey) ?? defaultValue) {
    hydrateFromPrefs();
  }

  final SharedPreferences _prefs;
  final String _key;
  final double _defaultValue;

  @override
  SharedPreferences get prefs => _prefs;

  @override
  String get key => _key;

  @override
  double readFrom(SharedPreferences prefs) =>
      prefs.getDouble(_key) ?? _defaultValue;

  @override
  Future<void> writeTo(SharedPreferences prefs, double value) async {
    await prefs.setDouble(_key, value);
  }
}

PrefDoubleSignal prefDouble(
  String key, {
  required double defaultValue,
}) {
  return PrefDoubleSignal(
    prefs: requireAppPrefs(),
    prefKey: key,
    defaultValue: defaultValue,
  );
}

PrefStringSignal prefString(
  String key, {
  String defaultValue = '',
  bool storeNullAsRemove = true,
}) {
  return PrefStringSignal(
    prefs: requireAppPrefs(),
    prefKey: key,
    defaultValue: defaultValue,
    storeNullAsRemove: storeNullAsRemove,
  );
}

PrefBoolSignal prefBool(
  String key, {
  bool defaultValue = false,
}) {
  return PrefBoolSignal(
    prefs: requireAppPrefs(),
    prefKey: key,
    defaultValue: defaultValue,
  );
}

PrefIntSignal prefInt(
  String key, {
  int defaultValue = 0,
}) {
  return PrefIntSignal(
    prefs: requireAppPrefs(),
    prefKey: key,
    defaultValue: defaultValue,
  );
}

String? readPrefString(String key) => requireAppPrefs().getString(key);

Future<void> writePrefString(String key, String value) async {
  await requireAppPrefs().setString(key, value);
}

Future<void> removePref(String key) async {
  await requireAppPrefs().remove(key);
}
