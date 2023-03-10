import 'dart:core';

import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'package:nitmgpt/models/record.dart';
import 'package:nitmgpt/pages/home/home_controller.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'watcher_controller.dart';
import 'package:unicons/unicons.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _watcherController = WatcherController.to;
  final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Wrap(
          children: [
            Obx(
              () => ElevatedButton.icon(
                onPressed: _watcherController.startNotificationService,
                icon: _watcherController.isListening.value
                    ? const Icon(UniconsLine.record_audio)
                    : const Icon(UniconsLine.play),
                label: Text(
                  _watcherController.isListening.value
                      ? "${"Listening".tr}..."
                      : "Start listening".tr,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 15),
            FilledButton.tonalIcon(
              onPressed: _watcherController.exportXlsx,
              icon: const Icon(UniconsLine.history),
              label: Text(
                "Export History".tr,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GetBuilder(
            init: HomeController(),
            builder: (controller) {
              return controller.tabController != null &&
                      _watcherController.detectedApps.isNotEmpty
                  ? TabBar(
                      overlayColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        return states.contains(MaterialState.focused)
                            ? null
                            : Colors.transparent;
                      }),
                      splashFactory: NoSplash.splashFactory,
                      indicator: DotIndicator(
                        color: Theme.of(context).primaryColor,
                        distanceFromCenter: 32,
                        radius: 3,
                        paintingStyle: PaintingStyle.fill,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      controller: controller.tabController,
                      tabs: _watcherController.detectedApps
                          .map(
                            (e) => Tab(
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: CircleAvatar(
                                  backgroundColor:
                                      const Color.fromARGB(255, 250, 249, 249),
                                  child: CachedMemoryImage(
                                    width: 25,
                                    height: 25,
                                    bytes: e.icon,
                                    uniqueKey: e.packageName,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      isScrollable: true,
                    )
                  : Container();
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GetBuilder(
              init: HomeController(),
              builder: (controller) {
                return controller.tabController != null &&
                        _watcherController.detectedApps.isNotEmpty
                    ? TabBarView(
                        controller: controller.tabController,
                        children:
                            _watcherController.detectedApps.map((element) {
                          List<Record> records = _watcherController.getRecords(
                              packageName: element.packageName);

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                                top: 5, left: 10, right: 10, bottom: 20),
                            itemCount: records.length,
                            itemBuilder: (BuildContext context, int index) {
                              Record r = records[index];

                              return NotificationTitle(
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
                        }).toList(),
                      )
                    : Container();
              },
            ),
          ),
        ],
      ),
    );
  }
}
