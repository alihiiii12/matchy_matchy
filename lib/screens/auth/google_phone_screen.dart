import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/google_phone_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_text_field.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class GooglePhoneScreen extends GetView<GooglePhoneController> {
  const GooglePhoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GooglePhoneController>()) {
      Get.put(GooglePhoneController());
    }

    final user = controller.user;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(AppStrings.appName),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.phone_android, size: 56, color: AppColors.accent),
                const SizedBox(height: 20),
                Text(AppStrings.googlePhoneTitle, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  user != null ? '${AppStrings.googlePhoneSubtitle}\n${user.email}' : AppStrings.googlePhoneSubtitle,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                Obx(
                  () => AppTextField(
                    label: AppStrings.contactPhone,
                    hint: AppStrings.enterContactPhone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    controller: controller.phoneController,
                    errorText: controller.phoneError.value,
                    onChanged: (_) => controller.phoneError.value = null,
                  ),
                ),
                const Spacer(),
                Obx(
                  () => GradientButton(
                    label: AppStrings.savePhone,
                    onPressed: controller.loading.value ? null : controller.save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
