import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<T?> showCommonDialog<T>({
  TextEditingController? controller,
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
  String cancelText = 'Cancel',
  String confirmText = 'Ok',
  Widget? description,
  WillPopCallback? onWillPop,
  String? textFieldPlaceholder,
  required String title,
}) {
  return Get.defaultDialog<T>(
    onWillPop: onWillPop,
    titlePadding: const EdgeInsets.only(top: 20),
    titleStyle: const TextStyle(fontSize: 22),
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    title: title,
    content: Column(
      children: [
        description ?? Container(),
        controller == null
            ? Container()
            : FractionallySizedBox(
                widthFactor: 0.8,
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: textFieldPlaceholder),
                ),
              ),
      ],
    ),
    cancel: onCancel == null
        ? null
        : TextButton(
            onPressed: onCancel,
            child: Text(cancelText, style: const TextStyle(fontSize: 20)),
          ),
    confirm: TextButton(
      onPressed: onConfirm,
      child: Text(confirmText, style: const TextStyle(fontSize: 20)),
    ),
  );
}
