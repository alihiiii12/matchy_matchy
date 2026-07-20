import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final loading = false.obs;
  final emailError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) {
      emailController.text = args.trim();
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sendOtp() async {
    final emailErr = AuthValidation.email(emailController.text);
    emailError.value = emailErr;
    if (emailErr != null) return;

    loading.value = true;
    try {
      final result = await AuthService.instance.requestForgotPassword(
        email: emailController.text.trim(),
      );
      if (result.directReset && result.resetToken != null) {
        Get.toNamed(
          AppRoutes.newPassword,
          arguments: ResetPasswordArgs(email: result.email, resetToken: result.resetToken!),
        );
        return;
      }
      Get.toNamed(
        AppRoutes.verifyOtp,
        arguments: OtpVerificationArgs(email: result.email, flow: OtpFlow.passwordReset),
      );
    } on SellerPasswordResetDenied catch (e) {
      await showSellerPasswordResetDeniedDialog(message: e.message);
    } on DioException catch (e) {
      showAppSnackBar(
        Get.context!,
        message: AuthService.instance.friendlyError(e),
        type: AppSnackBarType.error,
      );
    } catch (_) {
      showAppSnackBar(
        Get.context!,
        message: 'تعذر إرسال كود التحقق',
        type: AppSnackBarType.error,
      );
    } finally {
      loading.value = false;
    }
  }
}

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ForgotPasswordController());
  }
}
