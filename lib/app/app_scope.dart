import 'package:flutter/material.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/state/settings_store.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.settings,
    required this.watcher,
    required super.child,
  });

  final SettingsStore settings;
  final WatcherStore watcher;

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

  @override
  void initState() {
    super.initState();
    _settings.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _watcher.init();
    });
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
      child: SignalBuilder(
        builder: (context) {
          appLocale.value;
          return widget.child;
        },
      ),
    );
  }
}
