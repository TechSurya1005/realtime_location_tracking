import 'dart:async';
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:realtime_location_tracking/app/theme/AppColors.dart';

/// Global key that can be used to show snackbars/toasts without a BuildContext
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Types for toasts/snackbars
enum ToastType { info, success, error, warning }

/// Internal helper to map toast type to color & icon
Color _toastColor(ToastType type) {
  switch (type) {
    case ToastType.success:
      return AppColors.successColor;
    case ToastType.error:
      return AppColors.nope;
    case ToastType.warning:
      return AppColors.warningColor;
    case ToastType.info:
    return AppColors.secondary;
  }
}

IconData _toastIcon(ToastType type) {
  switch (type) {
    case ToastType.success:
      return Icons.check_circle_outline;
    case ToastType.error:
      return Icons.error_outline;
    case ToastType.warning:
      return Icons.warning_amber_outlined;
    case ToastType.info:
    return Icons.info_outline;
  }
}

/// Shows a SnackBar using the provided [context].
void showToast(
  BuildContext context,
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final color = _toastColor(type);
  final textColor = Colors.white;

  final snack = SnackBar(
    content: Row(
      children: [
        Icon(_toastIcon(type), color: textColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(color: textColor)),
        ),
      ],
    ),
    backgroundColor: color,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}

/// Shows a SnackBar using the global [rootScaffoldMessengerKey]. Useful where
/// a BuildContext isn't available (e.g. services or background tasks).
void showToastFromKey(
  String message, {
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = rootScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final color = _toastColor(type);
  final textColor = Colors.white;

  final snack = SnackBar(
    content: Row(
      children: [
        Icon(_toastIcon(type), color: textColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(color: textColor)),
        ),
      ],
    ),
    backgroundColor: color,
    duration: duration,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}

/// Hides the current snackbar on the provided [context]
void hideCurrentToast(BuildContext context) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

/// Show a configurable AwesomeDialog
Future<void> showAppDialog(
  BuildContext context, {
  Widget? icon,
  String? title,
  String? subtitle,
  bool barrierDismissible = true,
  bool showCancel = true,
  String okButtonText = 'OK',
  String cancelButtonText = 'Cancel',
  VoidCallback? onOk,
  Color? okButtonColor,
  DialogType dialogType = DialogType.success,
  AnimType animType = AnimType.scale,
}) async {
  final dialog = AwesomeDialog(
    context: context,
    dialogType: dialogType,
    animType: animType,
    headerAnimationLoop: false,
    dismissOnTouchOutside: barrierDismissible,
    dismissOnBackKeyPress: barrierDismissible,
    title: title,
    desc: subtitle,
    btnOkText: okButtonText,
    btnCancelText: cancelButtonText,
    btnOkOnPress: () {
      if (onOk != null) onOk();
    },
    btnCancelOnPress: () {},
    btnOkColor: okButtonColor,
    btnCancelColor: AppColors.googleRed,
    customHeader: icon,
  );

  dialog.show();
  return null;
}

