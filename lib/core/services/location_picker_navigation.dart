import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/delivery_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/screens/checkout/map_location_picker_screen.dart';

/// فتح شاشة اختيار الموقع على الخريطة (داخل التطبيق).
abstract final class LocationPickerNavigation {
  static Future<bool> open() async {
    DeliverySession.locationLoading = false;

    if (Get.isSnackbarOpen == true) {
      Get.closeAllSnackbars();
    }

    final context = Get.context ?? Get.key.currentContext;
    if (context == null) {
      showMatchySnackBar(message: AppStrings.mapPickerOpenFailed, type: AppSnackBarType.error);
      return false;
    }

    try {
      final result = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const MapLocationPickerScreen(),
        ),
      );
      return result == true;
    } catch (_) {
      showMatchySnackBar(message: AppStrings.mapPickerOpenFailed, type: AppSnackBarType.error);
      return false;
    }
  }
}
