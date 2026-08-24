import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loading = false.obs;
  final googleLoading = false.obs;
  final emailError = RxnString();
  final passwordError = RxnString();

  bool get socialLoading => googleLoading.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool validate() {
    final emailErr = AuthValidation.email(emailController.text);
    final passwordErr = AuthValidation.password(passwordController.text);
    emailError.value = emailErr;
    passwordError.value = passwordErr;
    update();
    return emailErr == null && passwordErr == null;
  }

  void clearEmailError() {
    if (emailError.value == null) return;
    emailError.value = null;
    update();
  }

  void clearPasswordError() {
    if (passwordError.value == null) return;
    passwordError.value = null;
    update();
  }

  void _showError(String message) {
    showMatchySnackBar(message: message, type: AppSnackBarType.error);
  }

  Future<void> login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!validate()) {
      _showError(emailError.value ?? passwordError.value ?? AppStrings.emailRequired);
      return;
    }
    if (loading.value) return;

    loading.value = true;
    update();
    try {
      await AuthService.instance.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.offAllNamed(AppRoutes.main);
    } on AdminMobileBlockedException catch (_) {
      _showError(AppStrings.adminMobileBlocked);
      Get.offAllNamed(AppRoutes.login);
    } on AuthPendingVerification catch (e) {
      Get.toNamed(AppRoutes.verifyOtp, arguments: e.email);
    } on DioException catch (e) {
      _showError(AuthService.instance.friendlyError(e));
    } catch (_) {
      _showError('تعذر تسجيل الدخول');
    } finally {
      if (!isClosed) {
        loading.value = false;
        update();
      }
    }
  }

  Future<void> signInWithGoogle() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (googleLoading.value) return;
    googleLoading.value = true;
    update();
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result.requiresPhone) {
        Get.offAllNamed(AppRoutes.googlePhone);
      } else {
        Get.offAllNamed(AppRoutes.main);
      }
    } on AdminMobileBlockedException catch (_) {
      _showError(AppStrings.adminMobileBlocked);
      Get.offAllNamed(AppRoutes.login);
    } on GoogleSignInCanceled {
      // User cancelled — no message.
    } on StateError catch (e) {
      _showError(e.message);
    } on DioException catch (e) {
      _showError(AuthService.instance.friendlyError(e));
    } catch (_) {
      _showError(AppStrings.googleSignInFailed);
    } finally {
      if (!isClosed) {
        googleLoading.value = false;
        update();
      }
    }
  }

  Future<void> goToForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.toNamed(AppRoutes.forgotPassword);
      return;
    }

    final emailErr = AuthValidation.email(email);
    if (emailErr != null) {
      emailError.value = emailErr;
      update();
      _showError(emailErr);
      return;
    }

    try {
      final result = await AuthService.instance.requestForgotPassword(email: email);
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
      _showError(AuthService.instance.friendlyError(e));
    }
  }

  void goToCreateAccount() => Get.toNamed(AppRoutes.createAccount);

  void continueAsGuest() => Get.offAllNamed(AppRoutes.main);
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>(force: true);
    }
    Get.put(LoginController());
  }
}
