import 'dart:core';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'watcher_controller.dart';
import 'package:unicons/unicons.dart';
import '../../models/record.dart';
import '../../theme.dart';

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
                          return Card(
                            elevation: 0,
                            // color: Theme.of(context).colorScheme.surfaceVariant,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: primaryColor,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Column(
                              children: [
                                Text(r.appName ?? ''),
                                Text(r.notificationTitle ?? ''),
                                Text(r.notificationText ?? ''),
                              ],
                            ),
                          );
                          // return ListTile(
                          //   onTap: () {
                          //     // _ruleFormController.clearTextField();
                          //     // _ruleFormController.selectedApp.value = app;
                          //     Get.back();
                          //   },
                          //   leading: Container(
                          //     width: 50,
                          //     height: 50,

                          //     // child: CachedMemoryImage(
                          //     //   bytes: app.icon,
                          //     //   width: 50,
                          //     //   height: 50,
                          //     //   uniqueKey: app.packageName,
                          //     // ),
                          //   ),

                          //   trailing: Text(r.appName ?? ''),
                          //   // subtitle: Text(app.packageName),
                          // );
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
