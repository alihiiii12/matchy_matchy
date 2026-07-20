import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/otp_verification_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class OtpVerificationScreen extends GetView<OtpVerificationController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.accent),
              const SizedBox(height: 20),
              Text(AppStrings.otpTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                AppStrings.otpSubtitle(controller.email),
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              Text(AppStrings.otpCodeLabel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Obx(
                () => TextField(
                  controller: controller.codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 12),
                  decoration: InputDecoration(
                    hintText: '000000',
                    counterText: '',
                    errorText: controller.codeError.value,
                  ),
                  onChanged: (_) => controller.codeError.value = null,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => GradientButton(
                  label: controller.verifyButtonLabel,
                  onPressed: controller.loading.value ? null : controller.verify,
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                () => Center(
                  child: TextButton(
                    onPressed: (controller.resendSeconds.value > 0 || controller.resending.value)
                        ? null
                        : controller.resend,
                    child: Text(
                      controller.resendSeconds.value > 0
                          ? AppStrings.otpResendIn(controller.resendSeconds.value)
                          : AppStrings.otpResend,
                      style: TextStyle(
                        color: controller.resendSeconds.value > 0 ? AppColors.textSecondary : AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
