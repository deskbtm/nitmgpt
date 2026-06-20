import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/empty.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/services/device_apps.dart';
import 'package:nitmgpt/services/permanent_listener/background_service_host.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:nitmgpt/theme/app_theme.dart';
import 'package:signals_flutter/signals_flutter.dart';

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
  StreamSubscription<Map<String, dynamic>?>? _backgroundServiceSub;

  @override
  void initState() {
    super.initState();
    _backgroundServiceSub = FlutterBackgroundService()
        .on(BackgroundServiceAction.updateRecords)
        .listen((_) {
      if (!_watcherReady) return;
      _watcher.onBackgroundServiceRecordsUpdated();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_watcherReady) {
      _watcherReady = true;
      _watcher = AppScope.of(context).watcher;
    }
  }

  @override
  void dispose() {
    _backgroundServiceSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_watcherReady) {
      return const SizedBox.shrink();
    }

    return TabPageShell(
      body: Padding(
        padding: EdgeInsets.only(
          top: TabPageShell.scrollTopPadding(context),
        ),
        child: SignalBuilder(
          builder: (context) {
            final searchQuery = _watcher.notificationSearchQuery.value;
            if (searchQuery.trim().isNotEmpty) {
              return _HomeSearchResultsList(
                watcher: _watcher,
                searchQuery: searchQuery,
                formatter: _formatter,
              );
            }

            return SignalBuilder(
              builder: (context) {
                final apps = _watcher.detectedApps.value;
                if (apps.isEmpty) {
                  return AppEmptyState(
                    title: 'No records yet'.tr,
                    subtitle: 'Empty records hint'.tr,
                  );
                }

                final safeIndex =
                    _selectedTabIndex.clamp(0, apps.length - 1);
                final selectedApp = apps[safeIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeAppTabBar(
                      apps: apps,
                      selectedTabIndex: _selectedTabIndex,
                      onTabSelected: (index) =>
                          setState(() => _selectedTabIndex = index),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _HomeRecordsList(
                        watcher: _watcher,
                        selectedApp: selectedApp,
                        formatter: _formatter,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HomeAppTabBar extends StatelessWidget {
  const _HomeAppTabBar({
    required this.apps,
    required this.selectedTabIndex,
    required this.onTabSelected,
  });

  final List<ApplicationWithIcon> apps;
  final int selectedTabIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = selectedTabIndex.clamp(0, apps.length - 1);

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: apps.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final app = apps[index];
          final selected = index == safeIndex;
          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: const Color.fromARGB(255, 250, 249, 249),
                child: AppIconImage(
                  width: 22,
                  height: 22,
                  bytes: app.icon,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeSearchResultsList extends StatelessWidget {
  const _HomeSearchResultsList({
    required this.watcher,
    required this.searchQuery,
    required this.formatter,
  });

  final WatcherStore watcher;
  final String searchQuery;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        watcher.recordsRevision.value;
        final records = watcher.getRecordsMatchingSearch(searchQuery);
        if (records.isEmpty) {
          return AppEmptyState(
            title: 'No matching notifications'.tr,
            subtitle: 'No matching notifications hint'.tr,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: 5,
            left: 10,
            right: 10,
            bottom: TabPageShell.scrollBottomPadding(context),
          ),
          cacheExtent: 400,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemCount: records.length,
          itemBuilder: (BuildContext context, int index) {
            final record = records[index];
            final app = watcher.appIconForPackage(record.packageName);

            return NotificationTitle(
              key: ValueKey(
                record.uid ?? 'search-${record.packageName}-${record.createTime}',
              ),
              title: record.notificationTitle,
              subtitle: record.notificationText,
              appName: record.appName ?? app?.appName,
              icon: app?.icon,
              tileKey: record.packageName,
              adProbability: record.adProbability,
              spamProbability: record.spamProbability,
              dateTime: record.createTime != null
                  ? formatter.format(record.createTime!)
                  : '',
            );
          },
        );
      },
    );
  }
}

class _HomeRecordsList extends StatelessWidget {
  const _HomeRecordsList({
    required this.watcher,
    required this.selectedApp,
    required this.formatter,
  });

  final WatcherStore watcher;
  final ApplicationWithIcon selectedApp;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        watcher.recordsRevision.value;
        final records =
            watcher.getRecords(packageName: selectedApp.packageName);

        if (records.isEmpty) {
          return AppEmptyState(
            title: 'No records yet'.tr,
            subtitle: 'Empty records hint'.tr,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(
            top: 5,
            left: 10,
            right: 10,
            bottom: TabPageShell.scrollBottomPadding(context),
          ),
          cacheExtent: 400,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemCount: records.length,
          itemBuilder: (BuildContext context, int index) {
            final r = records[index];

            return NotificationTitle(
              key: ValueKey(r.uid ?? '${r.packageName}-${r.createTime}'),
              title: r.notificationTitle,
              subtitle: r.notificationText,
              appName: r.appName,
              icon: selectedApp.icon,
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
