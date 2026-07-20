import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/splash_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/brand_logo.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // يفعّل SplashController.onInit (التنقل بعد 2 ثانية)
    final _ = controller;

    final logoSize = MediaQuery.sizeOf(context).width * 0.58;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.brandGradientVertical),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandLogo(
              size: logoSize,
              circular: true,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
            ),
            const SizedBox(height: 32),
            Text(
              AppStrings.splashTagline,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
