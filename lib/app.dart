import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/bindings/initial_binding.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_theme.dart';
import 'package:matchy_matchy/routing/app_pages.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class ZadakApp extends StatelessWidget {
  const ZadakApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    // لا تضع GetMaterialApp داخل Obx — إعادة إنشائه تعيد التطبيق للسبلاش
    // وتُلغي شاشة الدخول وكأن زر «دخول» لا يفعل شيئاً.
    return GetMaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.themeMode.value,
      locale: languageController.locale,
      fallbackLocale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.delegates,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.cupertino,
      builder: (context, child) {
        return Obx(() {
          final mode = themeController.themeMode.value;
          languageController.code.value; // تحديث عناوين AppStrings عند تبديل اللغة
          final theme = mode == ThemeMode.dark ? AppTheme.dark : AppTheme.light;
          return AnimatedTheme(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            data: theme,
            child: child ?? const SizedBox.shrink(),
          );
        });
      },
    );
  }
}
