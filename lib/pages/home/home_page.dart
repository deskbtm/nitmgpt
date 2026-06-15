import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:unicons/unicons.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
  int _selectedTabIndex = 0;
  late WatcherStore _watcher;
  bool _watcherReady = false;
  bool _mockSeedRequested = false;
  EffectCleanup? _detectedAppsEffect;
  List<_AppTab> _cachedTabs = const [];

  @override
  void initState() {
    super.initState();
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_watcherReady) {
      _watcherReady = true;
      _watcher = AppScope.of(context).watcher;
      unawaited(_bootstrapHomeData());

      _detectedAppsEffect = effect(() {
        final apps = _watcher.detectedApps.value;
        if (apps.isEmpty) {
          _selectedTabIndex = 0;
          _cachedTabs = const [];
        } else {
          if (_selectedTabIndex >= apps.length) {
            _selectedTabIndex = 0;
          }
          _cachedTabs = apps
              .map(
                (e) => _AppTab(
                  packageName: e.packageName,
                  icon: e.icon,
                ),
              )
              .toList();
        }
        setState(() {});
      });
    }
  }

  Future<void> _bootstrapHomeData() async {
    if (kDebugMode && !_mockSeedRequested) {
      _mockSeedRequested = true;
      await _watcher.seedHomeMockDataIfEmpty();
    }
    if (!mounted) return;
    _watcher.refreshDetectedApps();
    setState(() {});
  }

  void _onForegroundTaskData(Object data) {
    if (!_watcherReady) return;
    if (data is Map &&
        data['action'] == ForegroundTaskAction.updateRecords) {
      _watcher.onForegroundTaskRecordsUpdated();
    }
  }

  @override
  void dispose() {
    _detectedAppsEffect?.call();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_watcherReady) {
      return const SizedBox.shrink();
    }

    return TabPageShell(
      appBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SignalBuilder(
          builder: (context) {
            final listening = _watcher.isListening.value;
            return Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _watcher.startNotificationService,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(
                    listening ? UniconsLine.record_audio : UniconsLine.play,
                    size: 18,
                  ),
                  label: Text(
                    listening ? '${'Listening'.tr}...' : 'Start listening'.tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _watcher.exportXlsx,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(UniconsLine.history, size: 18),
                  label: Text(
                    'Export History'.tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_cachedTabs.isNotEmpty)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cachedTabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final tab = _cachedTabs[index];
                  final selected = index == _selectedTabIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            const Color.fromARGB(255, 250, 249, 249),
                        child: AppIconImage(
                          width: 22,
                          height: 22,
                          bytes: tab.icon,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: _HomeRecordsList(
              watcher: _watcher,
              selectedTabIndex: _selectedTabIndex,
              formatter: _formatter,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTab {
  const _AppTab({
    required this.packageName,
    required this.icon,
  });

  final String packageName;
  final Uint8List? icon;
}

class _HomeRecordsList extends StatelessWidget {
  const _HomeRecordsList({
    required this.watcher,
    required this.selectedTabIndex,
    required this.formatter,
  });

  final WatcherStore watcher;
  final int selectedTabIndex;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        watcher.recordsRevision.value;
        final apps = watcher.detectedApps.value;
        if (apps.isEmpty || selectedTabIndex >= apps.length) {
          return const SizedBox.shrink();
        }

        final element = apps[selectedTabIndex];
        final records = watcher.getRecords(packageName: element.packageName);

        return ListView.builder(
          padding: const EdgeInsets.only(
            top: 5,
            left: 10,
            right: 10,
            bottom: 20,
          ),
          itemCount: records.length,
          itemBuilder: (BuildContext context, int index) {
            final r = records[index];

            return NotificationTitle(
              key: ValueKey('${r.packageName}-${r.createTime}-$index'),
              title: r.notificationTitle,
              subtitle: r.notificationText,
              appName: r.appName,
              icon: element.icon,
              tileKey: r.packageName,
              adProbability: r.adProbability,
              spamProbability: r.spamProbability,
              dateTime: r.createTime != null
                  ? formatter.format(r.createTime!)
                  : '',
            );
          },
        );
      },
    );
  }
}
