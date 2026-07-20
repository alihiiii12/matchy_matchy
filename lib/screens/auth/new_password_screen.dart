import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/new_password_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class NewPasswordScreen extends GetView<NewPasswordController> {
  const NewPasswordScreen({super.key});

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
              Text(AppStrings.newPasswordTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(AppStrings.newPasswordSubtitle),
              const SizedBox(height: 32),
              Obx(
                () => AppTextField(
                  label: AppStrings.newPassword,
                  hint: AppStrings.enterNewPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  controller: controller.passwordController,
                  errorText: controller.passwordError.value,
                  onChanged: (_) => controller.passwordError.value = null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: AppStrings.confirmPassword,
                  hint: AppStrings.confirmNewPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  controller: controller.confirmPasswordController,
                  errorText: controller.confirmPasswordError.value,
                  onChanged: (_) => controller.confirmPasswordError.value = null,
                ),
              ),
              const Spacer(),
              Obx(
                () => GradientButton(
                  label: AppStrings.updatePassword,
                  onPressed: controller.loading.value ? null : controller.submit,
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
