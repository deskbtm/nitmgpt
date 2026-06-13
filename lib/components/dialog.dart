import 'package:flutter/material.dart';
import 'package:nitmgpt/core/localization/app_locale.dart';

typedef DialogCallback = Future<void> Function(BuildContext dialogContext);
typedef DialogActionsBuilder = List<Widget> Function(BuildContext dialogContext);

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
  return showDialog<T>(
    context: context,
    barrierDismissible: onBackPressed == null && barrierDismissible,
    builder: (dialogContext) {
      final actions = actionsBuilder?.call(dialogContext) ?? [];
      return _AppDialogShell(
        title: title,
        content: content ?? const SizedBox.shrink(),
        actions: actions,
        onBackPressed: onBackPressed,
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
          ? Text(
              message,
              style: const TextStyle(fontSize: 16, height: 1.45),
            )
          : null);

  return showAppDialog<T>(
    context: context,
    title: title,
    content: body,
    onBackPressed: onBackPressed,
    actionsBuilder: (dialogContext) {
      final actions = <Widget>[];
      if (cancelText != null && onCancel != null) {
        actions.add(
          TextButton(
            onPressed: () => onCancel(dialogContext),
            child: Text(cancelText),
          ),
        );
      }
      actions.add(
        FilledButton(
          onPressed: () => onConfirm?.call(dialogContext),
          child: Text(confirmText),
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
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description != null) ...[
          description,
          const SizedBox(height: 12),
        ],
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            suffix: suffix,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    ),
    actionsBuilder: (dialogContext) {
      final actions = <Widget>[];
      if (cancelText != null) {
        actions.add(
          TextButton(
            onPressed: () {
              if (onCancel != null) {
                onCancel(dialogContext);
              } else {
                popDialog(dialogContext);
              }
            },
            child: Text(cancelText),
          ),
        );
      }
      actions.add(
        FilledButton(
          onPressed: () => onConfirm?.call(dialogContext),
          child: Text(confirmText),
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
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return FractionallySizedBox(
        heightFactor: heightFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: builder(sheetContext),
          ),
        ),
      );
    },
  );
}

class _AppDialogShell extends StatelessWidget {
  const _AppDialogShell({
    required this.title,
    required this.content,
    required this.actions,
    this.onBackPressed,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final Future<bool> Function()? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBackPressed == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (onBackPressed != null && await onBackPressed!()) {
          if (context.mounted) popDialog(context);
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: SingleChildScrollView(child: content),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
