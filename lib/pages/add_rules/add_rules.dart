import 'package:get/get.dart';
import 'package:nitmgpt/pages/home/watcher_controller.dart';
import 'package:nitmgpt/theme.dart';
import 'package:unicons/unicons.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/pages/add_rules/rule_fields_map.dart';
import 'package:nitmgpt/pages/add_rules/rules_controller.dart';

class ProbabilityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  const ProbabilityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Advertisement probability",
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                backgroundColor: primaryColor,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        const Text('>', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: TextFormField(
            controller: controller,
            validator: validator,
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
      ],
    );
  }
}

class AddRulesPage extends GetView<RulesController> {
  AddRulesPage({super.key});

  final _watcherController = WatcherController.to;

  _showDeviceApps(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Obx(
            () => _watcherController.deviceApps.isEmpty
                ? const Center(
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: _watcherController.deviceApps.length,
                    itemBuilder: (BuildContext context, int index) {
                      ApplicationWithIcon app =
                          _watcherController.deviceApps[index];

                      return ListTile(
                        onTap: () {
                          controller.addSelectedApp(app);
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
              '`${e.field}` ',
              style: blockTextStyle,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: e.width,
              child: TextFormField(
                validator: controller.validator,
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
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Ignore apps".tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "Some permanent notifications will always trigger notification check, so you need to ignore or close it"
                          .tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Row(children: [
                      Text('Ignore system apps'.tr),
                      Obx(
                        () => Checkbox(
                          value: controller.ignoreSystemApps.value,
                          onChanged: controller.toggleIgnoreSystemApps,
                        ),
                      ),
                    ]),
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                _watcherController.getDeviceApps();
                                return _showDeviceApps(context);
                              },
                              style: ButtonStyle(
                                shape: MaterialStateProperty.all(
                                  const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ),
                              child: Text(
                                "Select app".tr,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            ...controller.selectedApp.map((element) {
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
                      "Filter conditions (ask ChatGPT)".tr,
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
                            const TextSpan(text: " , only return json."),
                          ],
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${'Limit'.tr} (24h ${'reset'.tr})".tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "Limit the number of ChatGPT API calls per 24 hours".tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 160,
                      child: TextFormField(
                        controller: controller.limitController,
                        validator: controller.validator,
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
                    const SizedBox(height: 20),
                    Text(
                      "Custom probability (0~1.0)".tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      "If set, remove the notification should be more than the probability set here"
                          .tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    ProbabilityTile(
                      validator: controller.validatorPercent,
                      title: 'Advertisement probability'.tr,
                      subtitle: '`ad_probability`',
                      controller: controller.adProbabilityController,
                    ),
                    const SizedBox(height: 10),
                    ProbabilityTile(
                      validator: controller.validatorPercent,
                      title: 'Spam probability'.tr,
                      subtitle: '`spam_probability`',
                      controller: controller.spamProbabilityController,
                    ),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await controller.submit();

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
