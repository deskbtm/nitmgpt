import 'dart:developer';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicons/unicons.dart';
import '../../theme.dart';
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
                    // FilledButton.tonalIcon(
                    //   onPressed: () async {
                    //     final openAI = OpenAI.instance.build(
                    //       token:
                    //           "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",
                    //       baseOption: HttpSetup(
                    //         receiveTimeout: 100000,
                    //         proxyUrl: '127.0.0.1:7890',
                    //       ),
                    //       isLogger: true,
                    //     );
                    //     final request = CompleteText(
                    //       prompt: '怎么评价chatgpt',
                    //       model: kTranslateModelV3,
                    //       maxTokens: 200,
                    //     );

                    //     var demo =
                    //         await openAI.onCompleteText(request: request);

                    //     print("$demo =======================");
                    //     log(demo!.choices[0].text);
                    //     // var box = await Hive.openBox('box');
                    //     // print(box.get('key'));
                    //     // .resolvePlatformSpecificImplementation<
                    //     //     AndroidFlutterLocalNotificationsPlugin>()
                    //     // ?.getActiveNotifications();
                    //   },
                    //   icon: const Icon(UniconsLine.history),
                    //   label: Text(
                    //     "demo",
                    //     style: const TextStyle(fontSize: 16),
                    //   ),
                    // ),
                  ],
                ),
              ),
              // ..._watcherController.records.reversed.map(
              //   (element) => ListTile(
              //     title: Row(
              //       crossAxisAlignment: CrossAxisAlignment.end,
              //       children: [
              //         Text(element.appName),
              //         const SizedBox(width: 10),
              //         Text(
              //           '${element.amount}￥',
              //           style: TextStyle(fontSize: 14, color: primaryColor),
              //         )
              //       ],
              //     ),
              //     subtitle: Text(
              //       element.createTime.toString(),
              //       style: const TextStyle(fontSize: 12, color: Colors.grey),
              //     ),
              //   ),
              // ),
              _watcherController.records.isEmpty
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
                  : Container(),
            ],
          );
        }),
      ),
    );
  }
}
