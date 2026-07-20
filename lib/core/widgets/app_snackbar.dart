import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

enum AppSnackBarType { success, error, info }

/// Margin above [GlowingBottomNavBar] (~64px + safe padding).
const double kSnackBarAboveNavMargin = 88;

Future<void> showSellerPasswordResetDeniedDialog({
  BuildContext? context,
  String? message,
}) async {
  final ctx = context ?? Get.context;
  if (ctx == null) return;

  await showDialog<void>(
    context: ctx,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppStrings.forgotPasswordTitle),
      content: Text(message ?? AppStrings.sellerPasswordResetDenied),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(AppStrings.done),
        ),
      ],
    ),
  );
}

/// GetX snackbar with auto-dismiss, swipe-to-dismiss, and margin above bottom nav.
void showMatchySnackBar({
  required String message,
  String? title,
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  SnackPosition position = SnackPosition.BOTTOM,
  bool aboveBottomNav = true,
  Color? backgroundColor,
  Color? colorText,
  VoidCallback? onTap,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (Get.isSnackbarOpen == true) {
    Get.closeAllSnackbars();
  }

  final background = backgroundColor ??
      switch (type) {
        AppSnackBarType.success => AppColors.success,
        AppSnackBarType.error => AppColors.error,
        AppSnackBarType.info => AppColors.primary,
      };
  final textColor = colorText ?? Colors.white;

  final bottom = position == SnackPosition.BOTTOM && aboveBottomNav
      ? kSnackBarAboveNavMargin
      : 16.0;

  Get.snackbar(
    title ?? AppStrings.appName,
    message,
    snackPosition: position,
    backgroundColor: background,
    colorText: textColor,
    margin: EdgeInsets.fromLTRB(16, 16, 16, bottom),
    borderRadius: 14,
    duration: duration,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    onTap: onTap != null ? (_) => onTap() : null,
    mainButton: actionLabel != null && onAction != null
        ? TextButton(
            onPressed: () {
              Get.closeAllSnackbars();
              onAction();
            },
            child: Text(
              actionLabel,
              style: TextStyle(
                color: textColor == Colors.white ? Colors.white : AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        : null,
  );
}

/// توافق مؤقت مع الاستدعاءات القديمة.
void showZadakSnackBar({
  required String message,
  String? title,
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  SnackPosition position = SnackPosition.BOTTOM,
  bool aboveBottomNav = true,
  Color? backgroundColor,
  Color? colorText,
  VoidCallback? onTap,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showMatchySnackBar(
    message: message,
    title: title,
    type: type,
    duration: duration,
    position: position,
    aboveBottomNav: aboveBottomNav,
    backgroundColor: backgroundColor,
    colorText: colorText,
    onTap: onTap,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppSnackBarType type = AppSnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  bool aboveBottomNav = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();

  late final Color background;
  late final IconData icon;

  switch (type) {
    case AppSnackBarType.success:
      background = AppColors.success;
      icon = Icons.check_circle_outline;
    case AppSnackBarType.error:
      background = AppColors.error;
      icon = Icons.error_outline;
    case AppSnackBarType.info:
      background = AppColors.primary;
      icon = Icons.info_outline;
  }

  final bottomMargin = aboveBottomNav ? kSnackBarAboveNavMargin : 16.0;

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomMargin),
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      elevation: 4,
    ),
  );
}
