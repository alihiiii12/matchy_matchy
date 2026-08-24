import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void goToCreateAccount() => Get.toNamed(AppRoutes.createAccount);

  void goToLogin() => Get.toNamed(AppRoutes.login);

  void continueAsGuest() => Get.offAllNamed(AppRoutes.main);
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OnboardingController());
  }
}
