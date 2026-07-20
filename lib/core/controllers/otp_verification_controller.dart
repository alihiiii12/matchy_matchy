import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class OtpVerificationController extends GetxController {
  late final String email;
  late final OtpFlow flow;
  final codeController = TextEditingController();
  final loading = false.obs;
  final resending = false.obs;
  final resendSeconds = 60.obs;
  final codeError = RxnString();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is OtpVerificationArgs) {
      email = args.email;
      flow = args.flow;
      final debug = args.debugOtp?.replaceAll(RegExp(r'\D'), '') ?? '';
      if (debug.length == 6) {
        codeController.text = debug;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isClosed || Get.context == null) return;
          showAppSnackBar(
            Get.context!,
            message: 'تعذر إرسال البريد محلياً. كود التطوير: $debug',
            type: AppSnackBarType.success,
          );
        });
      }
    } else {
      email = args as String;
      flow = OtpFlow.registration;
    }
    _startResendTimer();
  }

  String get verifyButtonLabel {
    switch (flow) {
      case OtpFlow.passwordReset:
      case OtpFlow.profilePasswordChange:
        return AppStrings.otpVerifyPasswordReset;
      case OtpFlow.profileUpdate:
        return AppStrings.otpVerifyProfileUpdate;
      case OtpFlow.registration:
        return AppStrings.otpVerify;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  void _startResendTimer() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (isClosed || resendSeconds.value <= 0) return;
      resendSeconds.value--;
      _startResendTimer();
    });
  }

  Future<void> verify() async {
    final code = codeController.text.trim();
    if (code.length != 6) {
      codeError.value = AppStrings.otpInvalid;
      return;
    }

    loading.value = true;
    codeError.value = null;

    try {
      if (flow == OtpFlow.passwordReset) {
        final resetToken = await AuthService.instance.verifyForgotPasswordOtp(
          email: email,
          code: code,
        );
        Get.offNamed(
          AppRoutes.newPassword,
          arguments: ResetPasswordArgs(email: email, resetToken: resetToken),
        );
        return;
      }

      if (flow == OtpFlow.profilePasswordChange) {
        final resetToken = await AuthService.instance.verifyProfileChangeOtp(code: code);
        Get.offNamed(
          AppRoutes.newPassword,
          arguments: ProfileResetPasswordArgs(resetToken: resetToken),
        );
        return;
      }

      if (flow == OtpFlow.profileUpdate) {
        await AuthService.instance.verifyProfileUpdateOtp(code: code);
        Get.back(result: true);
        return;
      }

      await AuthService.instance.verifyOtp(email: email, code: code);
      Get.offAllNamed(AppRoutes.main);
    } on SellerPasswordResetDenied catch (e) {
      await showSellerPasswordResetDeniedDialog(message: e.message);
      if (flow == OtpFlow.passwordReset) {
        Get.back();
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['insufficient_info'] == true) {
        codeError.value = AppStrings.insufficientInfo;
        return;
      }
      codeError.value = AuthService.instance.friendlyError(e);
    } catch (_) {
      showAppSnackBar(Get.context!, message: 'تعذر التحقق', type: AppSnackBarType.error);
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  Future<void> resend() async {
    if (resendSeconds.value > 0 || resending.value) return;

    resending.value = true;
    try {
      if (flow == OtpFlow.passwordReset) {
        await AuthService.instance.resendForgotPasswordOtp(email: email);
      } else if (flow == OtpFlow.profilePasswordChange) {
        await AuthService.instance.resendProfileChangeOtp();
      } else if (flow == OtpFlow.profileUpdate) {
        await AuthService.instance.resendProfileUpdateOtp();
      } else {
        final debugOtp = await AuthService.instance.resendOtp(email: email);
        final debug = debugOtp?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (debug.length == 6) {
          codeController.text = debug;
          showAppSnackBar(
            Get.context!,
            message: 'تعذر إرسال البريد محلياً. كود التطوير: $debug',
            type: AppSnackBarType.success,
          );
        } else {
          showAppSnackBar(Get.context!, message: AppStrings.otpResent, type: AppSnackBarType.success);
        }
      }
      if (flow != OtpFlow.registration) {
        showAppSnackBar(Get.context!, message: AppStrings.otpResent, type: AppSnackBarType.success);
      }
      resendSeconds.value = 60;
      _startResendTimer();
    } on SellerPasswordResetDenied catch (e) {
      await showSellerPasswordResetDeniedDialog(message: e.message);
      if (flow == OtpFlow.passwordReset) {
        Get.back();
      }
    } on DioException catch (e) {
      showAppSnackBar(
        Get.context!,
        message: AuthService.instance.friendlyError(e),
        type: AppSnackBarType.error,
      );
    } finally {
      if (!isClosed) resending.value = false;
    }
  }
}

class OtpVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OtpVerificationController());
  }
}
