import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/controllers/featured_products_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/controllers/theme_controller.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/repositories/home_advertisement_repository.dart';
import 'package:matchy_matchy/core/repositories/home_slide_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/services/driver_location_tracker.dart';
import 'package:matchy_matchy/core/services/firebase_messaging_background.dart';
import 'package:matchy_matchy/core/services/location_access_service.dart';
import 'package:matchy_matchy/core/services/notification_service.dart';

/// تهيئة سريعة قبل أول إطار — لعرض السبلاش مباشرة.
abstract final class AppBootstrap {
  static Future<void>? _deferredFuture;

  static Future<void> minimalBeforeRunApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    Get.put<AuthService>(AuthService(), permanent: true);
    Get.put<CartController>(CartController(), permanent: true);
    Get.put<FavoritesController>(FavoritesController(), permanent: true);
    Get.put<FeaturedProductsController>(FeaturedProductsController(), permanent: true);
    Get.put(AppSearchController(), permanent: true);
    final themeController = Get.put(ThemeController(), permanent: true);
    await themeController.loadTheme();
    Get.put(LanguageController(), permanent: true);
  }

  /// إشعارات/موقع في الخلفية — لا يوقف السبلاش.
  static Future<void> startDeferred() {
    return _deferredFuture ??= _runDeferred();
  }

  static Future<void> _runDeferred() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}

    try {
      if (!Get.isRegistered<NotificationService>()) {
        await Get.putAsync<NotificationService>(() async {
          final service = NotificationService();
          await service.init().timeout(
            const Duration(seconds: 3),
            onTimeout: () => service,
          );
          return service;
        }, permanent: true).timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      if (!Get.isRegistered<NotificationService>()) {
        Get.put(NotificationService(), permanent: true);
      }
    }

    try {
      if (!Get.isRegistered<DriverLocationTracker>()) {
        Get.put(DriverLocationTracker(), permanent: true);
      }
      if (!Get.isRegistered<LocationAccessService>()) {
        Get.put(LocationAccessService(), permanent: true);
      }
    } catch (_) {}
  }

  /// أثناء السبلاش: جلسة + كتالوج بأقصى انتظار قصير.
  static Future<void> prepareSplashExit() async {
    // لا ننتظر الإشعارات/Firebase — حتى لا تتجمد السبلاش بدون google-services
    unawaited(startDeferred());

    try {
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 700)),
        AuthService.instance
            .restoreSession()
            .timeout(const Duration(seconds: 5), onTimeout: () {}),
        CatalogRepository.instance
            .load()
            .timeout(const Duration(seconds: 8), onTimeout: () {}),
        HomeSlideRepository.instance
            .load()
            .timeout(const Duration(seconds: 4), onTimeout: () {}),
        HomeAdvertisementRepository.instance
            .load()
            .timeout(const Duration(seconds: 4), onTimeout: () {}),
      ]).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
