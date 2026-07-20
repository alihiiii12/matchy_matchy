import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class ChangePasswordController extends GetxController {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final loading = false.obs;
  final currentPasswordError = RxnString();
  final newPasswordError = RxnString();
  final confirmPasswordError = RxnString();

  bool get isAdmin => AuthService.instance.user?.isAdmin == true;

  @override
  void onInit() {
    super.onInit();
    final user = AuthService.instance.user;
    if (user?.isSeller == true || user?.isDriver == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (isClosed) return;
        await showSellerPasswordResetDeniedDialog();
        Get.back();
      });
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  bool validate() {
    final currentErr = isAdmin
        ? null
        : AuthValidation.password(
            currentPasswordController.text,
            emptyMessage: AppStrings.currentPasswordRequired,
          );
    final newErr = AuthValidation.password(newPasswordController.text);
    final confirmErr = AuthValidation.confirmPassword(
      confirmPasswordController.text,
      newPasswordController.text,
    );

    currentPasswordError.value = currentErr;
    newPasswordError.value = newErr;
    confirmPasswordError.value = confirmErr;

    return currentErr == null && newErr == null && confirmErr == null;
  }

  Future<void> submit() async {
    if (!validate()) return;

    loading.value = true;
    try {
      final result = await AuthService.instance.changePassword(
        currentPassword: isAdmin ? null : currentPasswordController.text,
        password: newPasswordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );

      if (result.requiresOtp) {
        if (!isClosed) loading.value = false;

        final email = result.email ?? AuthService.instance.user?.email ?? '';
        if (result.currentPasswordIncorrect) {
          if (!isClosed) {
            currentPasswordError.value = AppStrings.currentPasswordIncorrect;
          }
          await Get.dialog<void>(
            AlertDialog(
              title: Text(AppStrings.currentPasswordIncorrect),
              content: Text(result.message ?? AppStrings.wrongPasswordOtpSent),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('متابعة'),
                ),
              ],
            ),
            barrierDismissible: false,
          );
        } else {
          showAppSnackBar(
            Get.context!,
            message: AppStrings.otpSentToEmail,
            type: AppSnackBarType.success,
          );
        }

        if (isClosed) return;
        Get.toNamed(
          AppRoutes.verifyOtp,
          arguments: OtpVerificationArgs(
            email: email,
            flow: OtpFlow.profilePasswordChange,
          ),
        );
        return;
      }

      showAppSnackBar(
        Get.context!,
        message: AppStrings.passwordChanged,
        type: AppSnackBarType.success,
      );
      Get.back();
    } on DioException catch (e) {
      _handleError(e);
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

  void _handleError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        newPasswordError.value = _firstError(errors['password']);
        confirmPasswordError.value = _firstError(errors['password_confirmation']);
        currentPasswordError.value = _firstError(errors['current_password']);
      }
    }

    if (currentPasswordError.value == null &&
        newPasswordError.value == null &&
        confirmPasswordError.value == null) {
      showAppSnackBar(
        Get.context!,
        message: AuthService.instance.friendlyError(error),
        type: AppSnackBarType.error,
      );
    }
  }

  String? _firstError(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePasswordController());
  }
}
