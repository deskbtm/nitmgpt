import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';
import 'package:nitmgpt/theme/app_theme.dart';

typedef DialogCallback = Future<void> Function(BuildContext dialogContext);

class AppDialogAction {
  const AppDialogAction({
    required this.label,
    this.isPrimary = false,
    this.isDestructive = false,
    this.onPressed,
  });

  final String label;
  final bool isPrimary;
  final bool isDestructive;
  final VoidCallback? onPressed;
}

typedef DialogActionsBuilder = List<AppDialogAction> Function(
  BuildContext dialogContext,
);

void popDialog(BuildContext dialogContext) {
  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop();
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  Widget? content,
  DialogActionsBuilder? actionsBuilder,
  bool barrierDismissible = true,
  Future<bool> Function()? onBackPressed,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: onBackPressed == null && barrierDismissible,
    builder: (dialogContext) {
      final actions = actionsBuilder?.call(dialogContext) ?? [];
      final dialog = CupertinoAlertDialog(
        title: Text(title),
        content: content,
        actions: [
          for (final action in actions)
            CupertinoDialogAction(
              isDefaultAction: action.isPrimary,
              isDestructiveAction: action.isDestructive,
              onPressed: action.onPressed,
              child: Text(action.label),
            ),
        ],
      );

      if (onBackPressed == null) {
        return dialog;
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (await onBackPressed()) {
            if (dialogContext.mounted) popDialog(dialogContext);
          }
        },
        child: dialog,
      );
    },
  );
}

Future<T?> showAppAlertDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  String confirmText = 'Ok',
  String? cancelText,
  DialogCallback? onConfirm,
  DialogCallback? onCancel,
  Future<bool> Function()? onBackPressed,
}) {
  final body = content ??
      (message != null
          ? Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            )
          : null);

  return showAppDialog<T>(
    context: context,
    title: title,
    content: body,
    onBackPressed: onBackPressed,
    actionsBuilder: (dialogContext) {
      final actions = <AppDialogAction>[];
      if (cancelText != null && onCancel != null) {
        actions.add(
          AppDialogAction(
            label: cancelText,
            onPressed: () => onCancel(dialogContext),
          ),
        );
      }
      actions.add(
        AppDialogAction(
          label: confirmText,
          isPrimary: true,
          onPressed: () => onConfirm?.call(dialogContext),
        ),
      );
      return actions;
    },
  );
}

Future<T?> showAppInputDialog<T>({
  required BuildContext context,
  required String title,
  required TextEditingController controller,
  String? hint,
  Widget? description,
  Widget? suffix,
  String confirmText = 'Ok',
  String? cancelText,
  DialogCallback? onConfirm,
  DialogCallback? onCancel,
}) {
  return showAppDialog<T>(
    context: context,
    title: title,
    content: Builder(
      builder: (fieldContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (description != null) ...[
              description,
              const SizedBox(height: 12),
            ],
            CupertinoTextField(
              controller: controller,
              placeholder: hint,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.tertiarySystemFill.resolveFrom(fieldContext),
                borderRadius: kTileBorderRadiusAll,
              ),
              suffix: suffix,
            ),
          ],
        );
      },
    ),
    actionsBuilder: (dialogContext) {
      final actions = <AppDialogAction>[];
      if (cancelText != null) {
        actions.add(
          AppDialogAction(
            label: cancelText,
            onPressed: () {
              if (onCancel != null) {
                onCancel(dialogContext);
              } else {
                popDialog(dialogContext);
              }
            },
          ),
        );
      }
      actions.add(
        AppDialogAction(
          label: confirmText,
          isPrimary: true,
          onPressed: () => onConfirm?.call(dialogContext),
        ),
      );
      return actions;
    },
  );
}

Future<T?> showAppPermissionDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required Future<bool> Function() canDismiss,
  required DialogCallback onConfirm,
}) {
  return showAppAlertDialog<T>(
    context: context,
    title: title,
    message: message,
    confirmText: 'Ok'.tr,
    onBackPressed: canDismiss,
    onConfirm: onConfirm,
  );
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.8,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
    shape: const RoundedRectangleBorder(
      borderRadius: kTileTopBorderRadius,
    ),
    builder: (sheetContext) {
      final sheetHeight = MediaQuery.sizeOf(sheetContext).height * heightFactor;
      return SizedBox(
        height: sheetHeight,
        width: double.infinity,
        child: builder(sheetContext),
      );
    },
  );
}
