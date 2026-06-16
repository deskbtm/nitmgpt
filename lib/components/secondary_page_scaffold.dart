import 'package:flutter/material.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/theme.dart';

/// Secondary page layout per ADR-0001: wallpaper, fixed glass back button,
/// large title scrolled inside [body].
class SecondaryPageScaffold extends StatelessWidget {
  const SecondaryPageScaffold({
    super.key,
    this.topActions,
    this.floatingActionButton,
    required this.body,
  });

  final List<Widget>? topActions;
  final Widget? floatingActionButton;
  final Widget body;

  static const _scrollTitleStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
  );

  /// Top inset for scroll content: safe area + nav row (44pt) + spacing.
  static double scrollTopPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).top + 44 + 12;
  }

  static Widget largeTitle(String title) {
    return Text(title, style: _scrollTitleStyle);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        kAppGlassBackground,
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: floatingActionButton,
          body: Stack(
            children: [
              Positioned.fill(child: body),
              Positioned(
                top: top,
                left: 8,
                child: const AppBarBackButton(),
              ),
              if (topActions != null && topActions!.isNotEmpty)
                Positioned(
                  top: top,
                  right: 8,
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: topActions!,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
