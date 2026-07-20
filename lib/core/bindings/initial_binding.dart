import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/controllers/featured_products_controller.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LanguageController>()) {
      Get.put<LanguageController>(LanguageController(), permanent: true);
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<CartController>()) {
      Get.put<CartController>(CartController(), permanent: true);
    }
    if (!Get.isRegistered<FavoritesController>()) {
      Get.put<FavoritesController>(FavoritesController(), permanent: true);
    }
    if (!Get.isRegistered<FeaturedProductsController>()) {
      Get.put<FeaturedProductsController>(FeaturedProductsController(), permanent: true);
    }
  }
}
