import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/components/app_icon.dart';
import 'package:nitmgpt/components/empty.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/services/device_apps.dart';
import 'package:nitmgpt/services/permanent_listener/background_service_host.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:nitmgpt/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateFormat _formatter = DateFormat('yyyy-MM-dd hh:mm:ss');
  final PageController _pageController = PageController();
  final ScrollController _tabBarScrollController = ScrollController();
  int _selectedTabIndex = 0;
  late WatcherStore _watcher;
  bool _watcherReady = false;
  String _searchQuery = '';
  List<ApplicationWithIcon> _apps = const [];
  StreamSubscription<Map<String, dynamic>?>? _backgroundServiceSub;
  VoidCallback? _searchQuerySub;
  VoidCallback? _appsSub;

  static const double _tabBarItemExtent = 52;

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
    if (_watcherReady) {
      return;
    }
    _watcherReady = true;
    _watcher = AppScope.of(context).watcher;
    _searchQuery = _watcher.notificationSearchQuery.value;
    _apps = List<ApplicationWithIcon>.from(_watcher.detectedApps.value);
    _searchQuerySub = _watcher.notificationSearchQuery.subscribe((_) {
      final next = _watcher.notificationSearchQuery.value;
      if (next == _searchQuery || !mounted) {
        return;
      }
      setState(() => _searchQuery = next);
    });
    _appsSub = _watcher.detectedApps.subscribe((_) {
      final next = _watcher.detectedApps.value;
      if (_sameDetectedApps(_apps, next) || !mounted) {
        return;
      }
      setState(() => _apps = List<ApplicationWithIcon>.from(next));
    });
  }

  @override
  void dispose() {
    _backgroundServiceSub?.cancel();
    _searchQuerySub?.call();
    _appsSub?.call();
    _pageController.dispose();
    _tabBarScrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _watcher.refreshHomeRecords();
  }

  void _onTabSelected(int index) {
    if (index == _selectedTabIndex) {
      return;
    }
    setState(() => _selectedTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    _scrollTabBarToIndex(index);
  }

  void _onPageChanged(int index) {
    if (index == _selectedTabIndex) {
      return;
    }
    setState(() => _selectedTabIndex = index);
    _scrollTabBarToIndex(index);
  }

  void _scrollTabBarToIndex(int index) {
    if (!_tabBarScrollController.hasClients) {
      return;
    }
    const horizontalPadding = 16.0;
    final targetOffset = (horizontalPadding + (index * _tabBarItemExtent) - 16)
        .clamp(0.0, _tabBarScrollController.position.maxScrollExtent);
    _tabBarScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _syncSelectedTabIndex(int safeIndex) {
    if (safeIndex == _selectedTabIndex) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedTabIndex = safeIndex);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(safeIndex);
      }
    });
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
        child: _searchQuery.trim().isNotEmpty
            ? _HomeSearchResultsList(
                watcher: _watcher,
                searchQuery: _searchQuery,
                formatter: _formatter,
                onRefresh: _handleRefresh,
              )
            : _apps.isEmpty
                ? RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: TabPageShell.scrollBottomPadding(context),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.45,
                          child: AppEmptyState(
                            title: 'No records yet'.tr,
                            subtitle: 'Empty records hint'.tr,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildAppTabs(context),
      ),
    );
  }

  Widget _buildAppTabs(BuildContext context) {
    final safeIndex = _selectedTabIndex.clamp(0, _apps.length - 1);
    _syncSelectedTabIndex(safeIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HomeAppTabBar(
          apps: _apps,
          selectedTabIndex: safeIndex,
          scrollController: _tabBarScrollController,
          onTabSelected: _onTabSelected,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _apps.length,
            itemBuilder: (context, index) {
              return _HomeRecordsList(
                watcher: _watcher,
                selectedApp: _apps[index],
                formatter: _formatter,
                onRefresh: index == safeIndex ? _handleRefresh : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

bool _sameDetectedApps(
  List<ApplicationWithIcon> previous,
  List<ApplicationWithIcon> next,
) {
  if (identical(previous, next)) {
    return true;
  }
  if (previous.length != next.length) {
    return false;
  }
  for (var index = 0; index < previous.length; index++) {
    if (previous[index].packageName != next[index].packageName) {
      return false;
    }
  }
  return true;
}

class _HomeAppTabBar extends StatelessWidget {
  const _HomeAppTabBar({
    required this.apps,
    required this.selectedTabIndex,
    required this.scrollController,
    required this.onTabSelected,
  });

  final List<ApplicationWithIcon> apps;
  final int selectedTabIndex;
  final ScrollController scrollController;
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
        controller: scrollController,
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

class _HomeSearchResultsList extends StatefulWidget {
  const _HomeSearchResultsList({
    required this.watcher,
    required this.searchQuery,
    required this.formatter,
    required this.onRefresh,
  });

  final WatcherStore watcher;
  final String searchQuery;
  final DateFormat formatter;
  final Future<void> Function()? onRefresh;

  @override
  State<_HomeSearchResultsList> createState() => _HomeSearchResultsListState();
}

class _HomeSearchResultsListState extends State<_HomeSearchResultsList> {
  late List<Record> _records;
  VoidCallback? _recordsSub;

  @override
  void initState() {
    super.initState();
    _records = _loadRecords();
    _recordsSub = widget.watcher.recordsRevision.subscribe((_) => _syncRecords());
  }

  @override
  void dispose() {
    _recordsSub?.call();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeSearchResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _records = _loadRecords();
    }
  }

  List<Record> _loadRecords() =>
      widget.watcher.getRecordsMatchingSearch(widget.searchQuery);

  void _syncRecords() {
    if (!mounted) {
      return;
    }
    final next = _loadRecords();
    if (_sameRecordSnapshot(_records, next)) {
      return;
    }
    setState(() => _records = next);
  }

  @override
  Widget build(BuildContext context) {
    return _HomeNotificationListBody(
      records: _records,
      onRefresh: widget.onRefresh,
      pageStorageKey: PageStorageKey<String>('home-search-${widget.searchQuery}'),
      emptyTitle: 'No matching notifications'.tr,
      emptySubtitle: 'No matching notifications hint'.tr,
      itemBuilder: (record) {
        final app = widget.watcher.appIconForPackage(record.packageName);
        return DismissibleNotificationTile(
          record: record,
          onDelete: widget.watcher.deleteRecord,
          child: NotificationTitle(
            margin: EdgeInsets.zero,
            title: record.notificationTitle,
            subtitle: record.notificationText,
            appName: record.appName ?? app?.appName,
            icon: app?.icon,
            tileKey: record.packageName,
            adProbability: record.adProbability,
            spamProbability: record.spamProbability,
            dateTime: record.createTime != null
                ? widget.formatter.format(record.createTime!)
                : '',
          ),
        );
      },
    );
  }
}

class _HomeRecordsList extends StatefulWidget {
  const _HomeRecordsList({
    required this.watcher,
    required this.selectedApp,
    required this.formatter,
    required this.onRefresh,
  });

  final WatcherStore watcher;
  final ApplicationWithIcon selectedApp;
  final DateFormat formatter;
  final Future<void> Function()? onRefresh;

  @override
  State<_HomeRecordsList> createState() => _HomeRecordsListState();
}

class _HomeRecordsListState extends State<_HomeRecordsList>
    with AutomaticKeepAliveClientMixin {
  late List<Record> _records;
  VoidCallback? _recordsSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _records = _loadRecords();
    _recordsSub = widget.watcher.recordsRevision.subscribe((_) => _syncRecords());
  }

  @override
  void dispose() {
    _recordsSub?.call();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _HomeRecordsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedApp.packageName != widget.selectedApp.packageName) {
      _records = _loadRecords();
    }
  }

  List<Record> _loadRecords() =>
      widget.watcher.getRecords(packageName: widget.selectedApp.packageName);

  void _syncRecords() {
    if (!mounted) {
      return;
    }
    final next = _loadRecords();
    if (_sameRecordSnapshot(_records, next)) {
      return;
    }
    setState(() => _records = next);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _HomeNotificationListBody(
      records: _records,
      onRefresh: widget.onRefresh,
      pageStorageKey: PageStorageKey<String>(
        'home-records-${widget.selectedApp.packageName}',
      ),
      emptyTitle: 'No records yet'.tr,
      emptySubtitle: 'Empty records hint'.tr,
      itemBuilder: (record) {
        return DismissibleNotificationTile(
          record: record,
          onDelete: widget.watcher.deleteRecord,
          child: NotificationTitle(
            margin: EdgeInsets.zero,
            title: record.notificationTitle,
            subtitle: record.notificationText,
            appName: record.appName,
            icon: widget.selectedApp.icon,
            tileKey: record.packageName,
            adProbability: record.adProbability,
            spamProbability: record.spamProbability,
            dateTime: record.createTime != null
                ? widget.formatter.format(record.createTime!)
                : '',
          ),
        );
      },
    );
  }
}

class _HomeNotificationListBody extends StatelessWidget {
  const _HomeNotificationListBody({
    required this.records,
    required this.onRefresh,
    required this.pageStorageKey,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.itemBuilder,
  });

  final List<Record> records;
  final Future<void> Function()? onRefresh;
  final PageStorageKey<String> pageStorageKey;
  final String emptyTitle;
  final String emptySubtitle;
  final Widget Function(Record record) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return _wrapRefresh(
        onRefresh: onRefresh,
        child: ListView(
          key: pageStorageKey,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: TabPageShell.scrollBottomPadding(context),
          ),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: AppEmptyState(
                title: emptyTitle,
                subtitle: emptySubtitle,
              ),
            ),
          ],
        ),
      );
    }

    return _wrapRefresh(
      onRefresh: onRefresh,
      child: ListView.builder(
        key: pageStorageKey,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: 5,
          left: 10,
          right: 10,
          bottom: TabPageShell.scrollBottomPadding(context),
        ),
        scrollCacheExtent: const ScrollCacheExtent.pixels(400),
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: true,
        itemCount: records.length,
        itemBuilder: (BuildContext context, int index) =>
            itemBuilder(records[index]),
      ),
    );
  }
}

Widget _wrapRefresh({
  required Future<void> Function()? onRefresh,
  required Widget child,
}) {
  final refresh = onRefresh;
  if (refresh == null) {
    return child;
  }
  return RefreshIndicator(onRefresh: refresh, child: child);
}

bool _sameRecordSnapshot(List<Record> previous, List<Record> next) {
  if (identical(previous, next)) {
    return true;
  }
  if (previous.length != next.length) {
    return false;
  }
  for (var index = 0; index < previous.length; index++) {
    final oldRecord = previous[index];
    final newRecord = next[index];
    if (oldRecord.uid != newRecord.uid ||
        oldRecord.adProbability != newRecord.adProbability ||
        oldRecord.spamProbability != newRecord.spamProbability ||
        oldRecord.notificationTitle != newRecord.notificationTitle ||
        oldRecord.notificationText != newRecord.notificationText) {
      return false;
    }
  }
  return true;
}
