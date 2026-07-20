import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/change_password_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.changePassword)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (!controller.isAdmin) ...[
                Obx(
                  () => AppTextField(
                    label: AppStrings.currentPassword,
                    hint: AppStrings.enterCurrentPassword,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    controller: controller.currentPasswordController,
                    errorText: controller.currentPasswordError.value,
                    onChanged: (_) => controller.currentPasswordError.value = null,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Obx(
                () => AppTextField(
                  label: AppStrings.newPassword,
                  hint: AppStrings.enterNewPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  controller: controller.newPasswordController,
                  errorText: controller.newPasswordError.value,
                  onChanged: (_) => controller.newPasswordError.value = null,
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}