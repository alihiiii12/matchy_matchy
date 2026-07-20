import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:matchy_matchy/core/controllers/onboarding_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  static const _pages = [
    (
      'كل ما تحتاجه في تطبيق واحد',
      'تسوق الأزياء والإلكترونيات والبقالة والمشروبات وأكثر مع روزي تاج.',
      'assets/images/onboarding/onboarding_1.png',
    ),
    (
      'تصفح حسب القسم',
      'اختر قسماً ثم استكشف التصنيفات الفرعية للعثور على ما تحتاجه.',
      'assets/images/onboarding/onboarding_2.png',
    ),
    (
      'توصيل سريع إلى بابك',
      'من الخضروات الطازجة إلى أحدث الهواتف — نوصلها بسرعة وأمان.',
      'assets/images/onboarding/onboarding_3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.put(OnboardingController());
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final page in _pages) _OnboardingPage(page: page),
                ],
              ),
            ),
            SmoothPageIndicator(
              controller: controller.pageController,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: AppColors.accent,
                dotColor: AppColors.border,
                expansionFactor: 3,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                label: AppStrings.createAccount,
                onPressed: controller.goToCreateAccount,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.goToLogin,
              child: Text(
              AppStrings.alreadyHaveAccount,
              style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page});

  final (String, String, String) page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset(
                page.$3,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  page.$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  page.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
