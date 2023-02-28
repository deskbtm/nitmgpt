import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/pages/add_rules/rules_controller.dart';
import 'package:unicons/unicons.dart';
import '../../theme.dart';
import '../home/watcher_controller.dart';

class AddRulesPage extends GetView<RulesController> {
  AddRulesPage({super.key});

  final _rulesController = RulesController.to;
  final _watcherController = WatcherController.to;

  _showDeviceApps(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 20),
              itemCount: _watcherController.deviceApps.length,
              itemBuilder: (BuildContext context, int index) {
                ApplicationWithIcon app = _watcherController.deviceApps[index];

                return ListTile(
                  onTap: () {
                    _rulesController.addSelectedApp(app);
                    Get.back();
                  },
                  leading: SizedBox(
                    width: 50,
                    height: 50,
                    child: CachedMemoryImage(
                      bytes: app.icon,
                      width: 50,
                      height: 50,
                      uniqueKey: app.packageName,
                    ),
                  ),
                  title: Text(app.appName),
                  subtitle: Text(app.packageName),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var blockTextStyle = TextStyle(
      background: Paint()..color = primaryColor,
      color: Colors.white,
    );

    var fieldsBlock = ruleFieldsMap.values.map((e) {
      return TextSpan(
        children: [
          const TextSpan(text: " , \nthe field "),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Text(
              e.field,
              style: blockTextStyle,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: e.width,
              child: TextField(
                controller: e.textEditingController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(leading: const AppBarBackButton()),
        body: ListView(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Form(
                key: _rulesController.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Ignore app (multi select)",
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    const Text(
                      "Some permanent notifications will always trigger notification check, so you needs to ignore or close it",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _showDeviceApps(context);
                              },
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Select app".tr,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            // const SizedBox(width: 15),
                            ..._rulesController.selectedApp.map((element) {
                              return Chip(
                                label: Text(element.appName),
                                avatar: CircleAvatar(
                                  backgroundColor: Colors.grey.shade800,
                                  child: CachedMemoryImage(
                                    bytes: element.icon,
                                    width: 50,
                                    height: 50,
                                    uniqueKey: element.packageName,
                                  ),
                                ),
                                onDeleted: () {
                                  controller.removeSelectedApp(element);
                                },
                                deleteIcon:
                                    const Icon(UniconsLine.multiply, size: 14),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Filter condition (ask chatgpt)",
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: "Determine ",
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 3.5,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Text(
                                  "{{template}}",
                                  style: blockTextStyle,
                                ),
                              ),
                              ...fieldsBlock,
                              const TextSpan(text: " , return json."),
                            ]),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await _rulesController.submit();

            Get.back();
          },
          tooltip: 'Add match rules',
          icon: const Icon(
            UniconsLine.check,
          ),
          label: Text('Done'.tr),
        ),
      ),
    );
  }
}
