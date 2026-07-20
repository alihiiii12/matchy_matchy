import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/forgot_password_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class ForgotPasswordScreen extends GetView<ForgotPasswordController> {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.forgotPasswordTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
              AppStrings.forgotPasswordSubtitle,
              style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Obx(
                () => AppTextField(
                  label: AppStrings.email,
                  hint: AppStrings.enterEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: controller.emailController,
                  errorText: controller.emailError.value,
                  onChanged: (_) => controller.emailError.value = null,
                ),
              ),
              const Spacer(),
              Obx(
                () => GradientButton(
                  label: AppStrings.sendResetLink,
                  onPressed: controller.loading.value ? null : controller.sendOtp,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
