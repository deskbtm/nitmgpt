import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/double_pop_exit.dart';
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
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          destinations: [
            NavigationDestination(
              icon: const Icon(UniconsLine.monitor_heart_rate),
              label: 'Home'.tr,
            ),
            NavigationDestination(
              icon: const Icon(UniconsLine.setting),
              label: 'Settings'.tr,
            ),
          ],
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}
