import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class LanguageScreen extends GetView<LanguageController> {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LanguageController>()) {
      Get.put(LanguageController(), permanent: true);
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.language)),
      body: Obx(
        () {
          final code = controller.code.value;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppStrings.languageHint,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              RadioListTile<String>(
                title: Text(AppStrings.arabic),
                value: 'ar',
                groupValue: code,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  if (v != null) controller.setLocaleCode(v);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'en',
                groupValue: code,
                activeColor: AppColors.accent,
                onChanged: (v) {
                  if (v != null) controller.setLocaleCode(v);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
