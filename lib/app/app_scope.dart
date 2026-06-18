import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nitmgpt/state/local_model_inference_prefs.dart';
import 'package:nitmgpt/state/local_model_store.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:nitmgpt/state/watcher_store.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.watcher,
    required this.localModels,
    required this.localModelInference,
    required super.child,
  });

  final SettingsStore settings;
  final WatcherStore watcher;
  final LocalModelStore localModels;
  final LocalModelInferencePrefs localModelInference;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class AppScopeHost extends StatefulWidget {
  const AppScopeHost({super.key, required this.child});

  final Widget child;

  @override
  State<AppScopeHost> createState() => _AppScopeHostState();
}

class _AppScopeHostState extends State<AppScopeHost> {
  late final SettingsStore _settings = SettingsStore();
  late final WatcherStore _watcher = WatcherStore(_settings);
  late final LocalModelInferencePrefs _localModelInference =
      LocalModelInferencePrefs();
  late final LocalModelStore _localModels = LocalModelStore(
    inferencePrefs: _localModelInference,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapStores());
    });
  }

  Future<void> _bootstrapStores() async {
    await _settings.init();
    unawaited(_watcher.init());
  }

  @override
  void dispose() {
    _watcher.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      settings: _settings,
      watcher: _watcher,
      localModels: _localModels,
      localModelInference: _localModelInference,
      child: widget.child,
    );
  }
}
