import 'package:flutter/material.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/theme.dart';

/// Secondary page layout per ADR-0001: wallpaper + transparent scaffold + glass back button.
class SecondaryPageScaffold extends StatelessWidget {
  const SecondaryPageScaffold({
    super.key,
    this.title,
    this.appBarActions,
    this.floatingActionButton,
    required this.body,
  });

  final String? title;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        kAppGlassBackground,
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: const AppBarBackButton(),
            title: title == null
                ? null
                : Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            actions: appBarActions,
          ),
          floatingActionButton: floatingActionButton,
          body: body,
        ),
      ],
    );
  }
}
