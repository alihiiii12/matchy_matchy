import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/controllers/login_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/brand_logo.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    final lang = Get.isRegistered<LanguageController>()
                        ? LanguageController.instance
                        : Get.put(LanguageController(), permanent: true);
                    lang.toggle();
                  },
                  child: Obx(() {
                    final lang = Get.isRegistered<LanguageController>()
                        ? LanguageController.instance
                        : Get.put(LanguageController(), permanent: true);
                    lang.code.value;
                    return Text(
                      lang.isEnglish ? 'العربية' : 'English',
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                    );
                  }),
                ),
              ),
              const Center(child: BrandLogo(dark: true, size: 140)),
              const SizedBox(height: 20),
              Obx(() {
                final lang = Get.isRegistered<LanguageController>()
                    ? LanguageController.instance
                    : Get.put(LanguageController(), permanent: true);
                lang.code.value;
                return Text(
                  AppStrings.loginAccount,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                );
              }),
              const SizedBox(height: 8),
              Obx(() {
                final lang = Get.isRegistered<LanguageController>()
                    ? LanguageController.instance
                    : Get.put(LanguageController(), permanent: true);
                lang.code.value;
                return Text(
                  AppStrings.loginSubtitle,
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }),
              const SizedBox(height: 32),
              GetBuilder<LoginController>(
                builder: (c) => AppTextField(
                  label: AppStrings.email,
                  hint: AppStrings.enterEmail,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  controller: c.emailController,
                  errorText: c.emailError.value,
                  onChanged: (_) => c.clearEmailError(),
                ),
              ),
              const SizedBox(height: 20),
              GetBuilder<LoginController>(
                builder: (c) => AppTextField(
                  label: AppStrings.password,
                  hint: AppStrings.enterPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  controller: c.passwordController,
                  errorText: c.passwordError.value,
                  onChanged: (_) => c.clearPasswordError(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.goToForgotPassword,
                  child: Text(
                    AppStrings.forgotPassword,
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => GradientButton(
                  label: AppStrings.signIn,
                  loading: controller.loading.value,
                  onPressed: controller.loading.value ? null : controller.login,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${AppStrings.noAccount} ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: controller.goToCreateAccount,
                    child: Text(
                      AppStrings.signUp,
                      style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: controller.continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: AppColors.accent.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Obx(() {
                    final lang = Get.isRegistered<LanguageController>()
                        ? LanguageController.instance
                        : Get.put(LanguageController(), permanent: true);
                    lang.code.value;
                    return Text(
                      AppStrings.continueAsGuest,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
