import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class CreateAccountController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final loading = false.obs;
  final nameError = RxnString();
  final phoneError = RxnString();
  final emailError = RxnString();
  final passwordError = RxnString();
  final confirmPasswordError = RxnString();

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  bool validate() {
    final nameErr = AuthValidation.name(nameController.text);
    final phoneErr = AuthValidation.phone(phoneController.text);
    final emailErr = AuthValidation.email(emailController.text);
    final passwordErr = AuthValidation.password(passwordController.text);
    final confirmErr = AuthValidation.confirmPassword(
      confirmPasswordController.text,
      passwordController.text,
    );
    nameError.value = nameErr;
    phoneError.value = phoneErr;
    emailError.value = emailErr;
    passwordError.value = passwordErr;
    confirmPasswordError.value = confirmErr;
    return nameErr == null &&
        phoneErr == null &&
        emailErr == null &&
        passwordErr == null &&
        confirmErr == null;
  }

  Future<void> register() async {
    if (!validate()) return;

    loading.value = true;
    try {
      final result = await AuthService.instance.register(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: confirmPasswordController.text,
      );
      Get.offNamed(
        AppRoutes.verifyOtp,
        arguments: OtpVerificationArgs(
          email: result.email,
          debugOtp: result.debugOtp,
        ),
      );
    } on DioException catch (e) {
      showAppSnackBar(
        Get.context!,
        message: AuthService.instance.friendlyError(e),
        type: AppSnackBarType.error,
      );
    } catch (_) {
      showAppSnackBar(
        Get.context!,
        message: 'تعذر إنشاء الحساب',
        type: AppSnackBarType.error,
      );
    } finally {
      loading.value = false;
    }
  }
}

class CreateAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CreateAccountController());
  }
}
