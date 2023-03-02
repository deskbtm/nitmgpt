import 'dart:core';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:nitmgpt/components/notification_tile.dart';
import 'watcher_controller.dart';
import 'package:unicons/unicons.dart';
import '../../models/record.dart';
import '../../theme.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _watcherController = WatcherController.to;
  final DateFormat formatter = DateFormat('yyyy-MM-dd hh:mm:ss');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 20, left: 15, right: 20),
                child: Wrap(
                  children: [
                    SizedBox(
                      child: ElevatedButton.icon(
                        onPressed: _watcherController.toggleNotificationService,
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
              _watcherController.records.value!.isEmpty
                  ? SizedBox(
                      height: Get.height - 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            UniconsLine.square_full,
                            size: 30,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: primaryColor,
                            ),
                          )
                        ],
                      ),
                    )
                  : Obx(
                      () => ListView.builder(
                        shrinkWrap: true,
                        padding:
                            const EdgeInsets.only(top: 20, left: 10, right: 10),
                        itemCount: _watcherController.records.value!.length,
                        itemBuilder: (BuildContext context, int index) {
                          Record r = _watcherController.records.value![index];
                          var icon = _watcherController
                              .deviceAppsMap.value[r.packageName]?.icon;

                          return NotificationTitle(
                            title: '的巴萨你顿巴斯的啊实打实的啊似乎大师',
                            subtitle: r.notificationText,
                            appName: r.appName,
                            icon: icon,
                            tileKey: r.packageName,
                            dateTime: r.createTime != null
                                ? formatter.format(r.createTime!)
                                : '',
                          );
                        },
                      ),
                    ),
            ],
          );
        }),
      ),
    );
  }
}
