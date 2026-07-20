import 'package:get/get.dart';
import 'package:matchy_matchy/core/bootstrap/app_bootstrap.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    try {
      await AppBootstrap.prepareSplashExit().timeout(const Duration(seconds: 12));
    } catch (_) {}
    if (isClosed) return;

    final user = AuthService.instance.user;
    if (user != null && user.isAdmin) {
      try {
        await AuthService.instance.rejectAdminMobileAccess();
      } catch (_) {}
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    if (AuthService.instance.isLoggedIn) {
      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SplashController());
  }
}
