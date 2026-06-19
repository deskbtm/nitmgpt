import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nitmgpt/app/routes.dart';
import 'package:nitmgpt/components/opaque_grouped_section.dart';
import 'package:nitmgpt/components/secondary_page_scaffold.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        appLocale.value;
        final topInset = SecondaryPageScaffold.scrollTopPadding(context);

        return SecondaryPageScaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(21, topInset, 21, 32),
            children: [
              SecondaryPageScaffold.largeTitle('Developer'.tr),
              const SizedBox(height: 20),
              OpaqueGroupedSection(
                margin: EdgeInsets.zero,
                children: [
                  OpaqueListTile(
                    title: Text('Ad notifications'.tr),
                    subtitle: Text('Preset ad notification samples'.tr),
                    showChevron: true,
                    onTap: () => context.push(AppRoutes.developerAdNotifications),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
