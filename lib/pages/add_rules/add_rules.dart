import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:nitmgpt/components/back_button.dart';
import 'package:nitmgpt/models/rule.dart';
import 'package:nitmgpt/pages/add_rules/rule_form_controller.dart';
import 'package:unicons/unicons.dart';
import 'add_rules_controller.dart';

class AddRulesPage extends GetView<RulesController> {
  AddRulesPage({super.key});

  final _ruleFormController = RuleFormController.to;

  _showDeviceApps(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 20),
              itemCount: _ruleFormController.deviceApps.length,
              itemBuilder: (BuildContext context, int index) {
                ApplicationWithIcon app = _ruleFormController.deviceApps[index];

                return ListTile(
                  onTap: () {
                    _ruleFormController.clearTextField();
                    _ruleFormController.selectedApp.value = app;
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
    var action = Get.parameters["action"] as String;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(leading: const AppBarBackButton()),
        body: ListView(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Form(
                key: _ruleFormController.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
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
                          child: _ruleFormController.selectedApp.value != null
                              ? Row(
                                  children: [
                                    CachedMemoryImage(
                                      bytes: _ruleFormController
                                          .selectedApp.value!.icon,
                                      width: 50,
                                      height: 50,
                                      uniqueKey: _ruleFormController
                                          .selectedApp.value!.packageName,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(_ruleFormController
                                            .selectedApp.value!.appName),
                                        Text(
                                          _ruleFormController
                                              .selectedApp.value!.packageName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              : Text("Select app".tr,
                                  style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      autofocus: false,
                      controller: _ruleFormController.matchPatternController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "Match rule".tr,
                        helperText: "Enter regular expression".tr,
                      ),
                      // 校验用户名
                      validator: _ruleFormController.validator,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Http method".tr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    Obx(
                      () => Row(
                        children: HttpMethods.values
                            .map(
                              (e) => Row(
                                children: [
                                  Text(e.name),
                                  Radio<HttpMethods>(
                                    value: e,
                                    groupValue:
                                        _ruleFormController.httpMethod.value,
                                    onChanged: _ruleFormController
                                        .selectCallbackHttpMethod,
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    TextFormField(
                      controller: _ruleFormController.callbackController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "callback url".tr,
                      ),
                      // 校验用户名
                      validator: _ruleFormController.validator,
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
            Rule? rule = _ruleFormController.submit();
            if (rule == null) {
              return;
            }
            switch (action) {
              case "create":
                bool result = await controller.addRule(rule);
                if (result) {
                  Get.back();
                } else {
                  Fluttertoast.showToast(msg: "${rule.packageName} has exist");
                }
                break;
              case "update":
                await controller.updateRule(rule);

                Get.back();
                break;
              default:
            }
          },
          tooltip: 'Add match rules',
          icon: const Icon(
            UniconsLine.check,
          ),
          label: Text(
            action == "create" ? 'Done'.tr : "Update".tr,
          ),
        ),
      ),
    );
  }
}
