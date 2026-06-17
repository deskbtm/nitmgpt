import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/app/app_scope.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/double_pop_exit.dart';
import 'package:nitmgpt/state/watcher_store.dart';
import 'package:nitmgpt/theme.dart';
import 'package:unicons/unicons.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _searchController = TextEditingController();
  bool _isSearchActive = false;
  WatcherStore? _watcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _watcher ??= AppScope.of(context).watcher;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index != 0) {
      _collapseSearch();
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _collapseSearch() {
    if (!_isSearchActive && _searchController.text.isEmpty) {
      return;
    }
    setState(() => _isSearchActive = false);
    _searchController.clear();
    _watcher?.notificationSearchQuery.value = '';
  }

  void _onSearchToggle(bool active) {
    if (active && widget.navigationShell.currentIndex != 0) {
      _onDestinationSelected(0);
    }
    setState(() => _isSearchActive = active);
    if (!active) {
      _searchController.clear();
      _watcher?.notificationSearchQuery.value = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DoublePopExit(
      child: Stack(
        fit: StackFit.expand,
        children: [
          kAppGlassBackground,
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: widget.navigationShell,
            bottomNavigationBar: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final sysBottom = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const tabWidth = 88.0;
    final isHomeTab = widget.navigationShell.currentIndex == 0;
    const iconSize = 28.0;
    final selectedIconColor = primaryColor;
    final unselectedIconColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    final indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.42);

    return Padding(
      padding: EdgeInsets.only(bottom: sysBottom),
      child: GlassSearchableBottomBar(
        tabWidth: tabWidth,
        horizontalPadding: 16,
        verticalPadding: kBottomBarVerticalPadding,
        barHeight: kBottomBarHeight,
        searchBarHeight: kBottomBarHeight,
        enableBlend: true,
        selectedIndex: widget.navigationShell.currentIndex,
        onTabSelected: _onDestinationSelected,
        isSearchActive: isHomeTab && _isSearchActive,
        selectedIconColor: selectedIconColor,
        unselectedIconColor: unselectedIconColor,
        labelFontSize: 10,
        iconSize: iconSize,
        iconLabelSpacing: 0,
        indicatorColor: indicatorColor,
        indicatorSettings: bottomBarIndicatorGlassSettings(isDark: isDark),
        quality: GlassQuality.premium,
        interactionBehavior: GlassInteractionBehavior.full,
        settings: bottomBarGlassSettings(isDark: isDark),
        searchConfig: GlassSearchBarConfig(
          hintText: 'Search notifications'.tr,
          controller: _searchController,
          onSearchToggle: _onSearchToggle,
          onChanged: (query) => _watcher?.notificationSearchQuery.value = query,
          onCancelTap: _collapseSearch,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          // searchIconColor: Colors.transparent,
          searchIcon: Icon(
            UniconsLine.search,
            color: unselectedIconColor,
            size: iconSize,
          ),
          showsCancelButton: false,
        ),
        tabs: [
          GlassBottomBarTab(
            label: 'Home'.tr,
            icon: const Icon(UniconsLine.monitor_heart_rate),
            activeIcon: const Icon(UniconsLine.monitor_heart_rate),
          ),
          GlassBottomBarTab(
            label: 'Settings'.tr,
            icon: const Icon(UniconsLine.setting),
            activeIcon: const Icon(UniconsLine.setting),
          ),
        ],
      ),
    );
  }
}
