import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class GooglePhoneController extends GetxController {
  final phoneController = TextEditingController();
  final loading = false.obs;
  final phoneError = RxnString();

  AuthUser? get user => AuthService.instance.user;

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  Future<void> save() async {
    final phoneErr = AuthValidation.phone(phoneController.text);
    if (phoneErr != null) {
      phoneError.value = phoneErr;
      return;
    }

    loading.value = true;
    phoneError.value = null;

    try {
      await AuthService.instance.completePhone(phoneController.text.trim());
      Get.offAllNamed(AppRoutes.main);
    } on AdminMobileBlockedException catch (_) {
      showAppSnackBar(
        Get.context!,
        message: AppStrings.adminMobileBlocked,
        type: AppSnackBarType.error,
      );
      Get.offAllNamed(AppRoutes.login);
    } on DioException catch (e) {
      showAppSnackBar(
        Get.context!,
        message: AuthService.instance.friendlyError(e),
        type: AppSnackBarType.error,
      );
    } finally {
      loading.value = false;
    }
  }
}

class GooglePhoneBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GooglePhoneController());
  }
}
