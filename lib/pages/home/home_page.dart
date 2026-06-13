import 'dart:core';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/permanent_listener_service/main.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
  TabController? _tabController;
  late WatcherStore _watcher;
  bool _watcherReady = false;
  EffectCleanup? _detectedAppsEffect;

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
      _watcher.refreshDetectedApps();

      _detectedAppsEffect = effect(() {
        final apps = _watcher.detectedApps.value;
        _tabController?.dispose();
        _tabController = apps.isEmpty
            ? null
            : TabController(length: apps.length, vsync: this);
        setState(() {});
      });
    }
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
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_watcherReady) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Wrap(
          children: [
            SignalBuilder(
              builder: (context) {
                return ElevatedButton.icon(
                  onPressed: _watcher.startNotificationService,
                  icon: _watcher.isListening.value
                      ? const Icon(UniconsLine.record_audio)
                      : const Icon(UniconsLine.play),
                  label: Text(
                    _watcher.isListening.value
                        ? '${'Listening'.tr}...'
                        : 'Start listening'.tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
            FilledButton.tonalIcon(
              onPressed: _watcher.exportXlsx,
              icon: const Icon(UniconsLine.history),
              label: Text(
                'Export History'.tr,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignalBuilder(
            builder: (context) {
              final apps = _watcher.detectedApps.value;
              if (_tabController == null || apps.isEmpty) {
                return const SizedBox.shrink();
              }

              return TabBar(
                overlayColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    return states.contains(WidgetState.focused)
                        ? null
                        : Colors.transparent;
                  },
                ),
                splashFactory: NoSplash.splashFactory,
                indicator: DotIndicator(
                  color: Theme.of(context).primaryColor,
                  distanceFromCenter: 32,
                  radius: 3,
                  paintingStyle: PaintingStyle.fill,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                controller: _tabController,
                tabs: apps
                    .map(
                      (e) => Tab(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 250, 249, 249),
                            child: AppIconImage(
                              width: 25,
                              height: 25,
                              bytes: e.icon,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                isScrollable: true,
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SignalBuilder(
              builder: (context) {
                final apps = _watcher.detectedApps.value;
                if (_tabController == null || apps.isEmpty) {
                  return const SizedBox.shrink();
                }

                return TabBarView(
                  controller: _tabController,
                  children: apps.map((element) {
                    final records =
                        _watcher.getRecords(packageName: element.packageName);

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
                          title: r.notificationTitle,
                          subtitle: r.notificationText,
                          appName: r.appName,
                          icon: element.icon,
                          tileKey: r.packageName,
                          adProbability: r.adProbability,
                          spamProbability: r.spamProbability,
                          dateTime: r.createTime != null
                              ? _formatter.format(r.createTime!)
                              : '',
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
