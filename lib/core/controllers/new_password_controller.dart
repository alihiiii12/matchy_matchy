import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class NewPasswordController extends GetxController {
  late final bool isProfileFlow;
  String? email;
  late final String resetToken;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final loading = false.obs;
  final passwordError = RxnString();
  final confirmPasswordError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ProfileResetPasswordArgs) {
      isProfileFlow = true;
      resetToken = args.resetToken;
    } else {
      final forgotArgs = args as ResetPasswordArgs;
      isProfileFlow = false;
      email = forgotArgs.email;
      resetToken = forgotArgs.resetToken;
    }
  }

  @override
  void onClose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  bool validate() {
    final passwordErr = AuthValidation.password(passwordController.text);
    final confirmErr = AuthValidation.confirmPassword(
      confirmPasswordController.text,
      passwordController.text,
    );
    passwordError.value = passwordErr;
    confirmPasswordError.value = confirmErr;
    return passwordErr == null && confirmErr == null;
  }

  Future<void> submit() async {
    if (!validate()) return;

    loading.value = true;
    try {
      if (isProfileFlow) {
        await AuthService.instance.resetProfilePassword(
          resetToken: resetToken,
          password: passwordController.text,
          passwordConfirmation: confirmPasswordController.text,
        );
        showAppSnackBar(
          Get.context!,
          message: AppStrings.passwordChanged,
          type: AppSnackBarType.success,
        );
        Get.until((route) => route.settings.name == AppRoutes.changePassword || route.isFirst);
        if (Get.currentRoute == AppRoutes.changePassword) {
          Get.back();
        }
        return;
      }

      await AuthService.instance.resetForgotPassword(
        email: email!,
        resetToken: resetToken,
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );
      showAppSnackBar(
        Get.context!,
        message: AppStrings.passwordChanged,
        type: AppSnackBarType.success,
      );
      Get.offAllNamed(AppRoutes.login);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['insufficient_info'] == true) {
        showAppSnackBar(
          Get.context!,
          message: AppStrings.insufficientInfo,
          type: AppSnackBarType.error,
        );
        return;
      }
      final errors = data is Map<String, dynamic> ? data['errors'] : null;
      if (errors is Map<String, dynamic>) {
        passwordError.value = _firstError(errors['password']);
        confirmPasswordError.value = _firstError(errors['password_confirmation']);
      }
      if (passwordError.value == null && confirmPasswordError.value == null) {
        showAppSnackBar(
          Get.context!,
          message: AuthService.instance.friendlyError(e),
          type: AppSnackBarType.error,
        );
      }
    } catch (_) {
      showAppSnackBar(
        Get.context!,
        message: 'تعذر تغيير كلمة المرور',
        type: AppSnackBarType.error,
      );
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  String? _firstError(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

class NewPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NewPasswordController());
  }
}
