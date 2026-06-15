import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/double_pop_exit.dart';
import 'package:nitmgpt/theme.dart';
import 'package:unicons/unicons.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
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
    const tabWidth = 99.0;
    const tabCount = 2;
    final pillWidth = tabWidth * tabCount;
    final selectedIconColor = primaryColor;
    final unselectedIconColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    final indicatorColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.42);

    return Padding(
      padding: EdgeInsets.only(bottom: sysBottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: pillWidth,
          child: GlassBottomBar(
            tabWidth: tabWidth,
            horizontalPadding: 0,
            verticalPadding: 8,
            enableBlend: true,
            selectedIndex: widget.navigationShell.currentIndex,
            onTabSelected: _onDestinationSelected,
            selectedIconColor: selectedIconColor,
            unselectedIconColor: unselectedIconColor,
            labelFontSize: 10,
            iconSize: 28,
            iconLabelSpacing: 0,
            indicatorColor: indicatorColor,
            indicatorSettings: bottomBarIndicatorGlassSettings(isDark: isDark),
            quality: GlassQuality.premium,
            interactionBehavior: GlassInteractionBehavior.full,
            settings: bottomBarGlassSettings(isDark: isDark),
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
        ),
      ),
    );
  }
}
