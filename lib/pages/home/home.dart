import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:nitmgpt/notification_utils.dart';
import 'package:unicons/unicons.dart';
import 'watcher_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _watcherController = WatcherController.to;

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
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        var box = await Hive.openBox('box');
                        print(box.get('key'));
                        // .resolvePlatformSpecificImplementation<
                        //     AndroidFlutterLocalNotificationsPlugin>()
                        // ?.getActiveNotifications();
                      },
                      icon: const Icon(UniconsLine.history),
                      label: Text(
                        "demo",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              ..._watcherController.records.reversed.map(
                (element) => ListTile(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(element.appName),
                      const SizedBox(width: 10),
                      Text(
                        '${element.amount}￥',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.green),
                      )
                    ],
                  ),
                  subtitle: Text(
                    element.createTime.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              _watcherController.records.isEmpty
                  ? SizedBox(
                      height: Get.height - 300,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            UniconsLine.square_full,
                            size: 30,
                            color: Colors.green.shade800,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Empty',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green.shade400,
                            ),
                          )
                        ],
                      ),
                    )
                  : Container(),
            ],
          );
        }),
      ),
    );
  }
}
