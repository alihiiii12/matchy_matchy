import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/create_account_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class CreateAccountScreen extends GetView<CreateAccountController> {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CreateAccountController>()) {
      Get.put(CreateAccountController());
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.createAccountTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(AppStrings.createAccountSubtitle),
              const SizedBox(height: 32),
              Obx(
                () => AppTextField(
                  label: AppStrings.fullName,
                  hint: AppStrings.enterFullName,
                  icon: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  controller: controller.nameController,
                  errorText: controller.nameError.value,
                  onChanged: (_) => controller.nameError.value = null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: AppStrings.contactPhone,
                  hint: AppStrings.enterContactPhone,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  controller: controller.phoneController,
                  errorText: controller.phoneError.value,
                  onChanged: (_) => controller.phoneError.value = null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: AppStrings.email,
                  hint: AppStrings.enterEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  controller: controller.emailController,
                  errorText: controller.emailError.value,
                  onChanged: (_) => controller.emailError.value = null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: AppStrings.password,
                  hint: AppStrings.createPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  controller: controller.passwordController,
                  errorText: controller.passwordError.value,
                  onChanged: (_) => controller.passwordError.value = null,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AppTextField(
                  label: AppStrings.confirmPassword,
                  hint: AppStrings.confirmPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  controller: controller.confirmPasswordController,
                  errorText: controller.confirmPasswordError.value,
                  onChanged: (_) => controller.confirmPasswordError.value = null,
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => GradientButton(
                  label: AppStrings.createAccount,
                  onPressed: controller.loading.value ? null : controller.register,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
