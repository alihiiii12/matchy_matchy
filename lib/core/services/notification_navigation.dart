import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/models/app_notification.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

/// توجيه الإشعار أو الطلب إلى الشاشة المناسبة حسب دور المستخدم.
abstract final class NotificationNavigation {
  static const _customerOrderTypes = {
    'order_placed',
    'payment_confirmed',
    'delivery_time',
    'awaiting_receipt',
    'order_delivered',
    'order_rejected',
  };

  static Future<void> open(AppNotificationItem notification) {
    return openFromPayload(
      type: notification.type,
      data: notification.data ?? {},
      orderId: notification.orderId,
      deliveryId: notification.deliveryId,
    );
  }

  static Future<void> openFromPayload({
    required String type,
    required Map<String, dynamic> data,
    int? orderId,
    String? deliveryId,
  }) async {
    await waitUntilReady();

    final user = AuthService.instance.user;
    if (user == null) {
      await _openRoute(AppRoutes.notifications);
      return;
    }

    final resolvedOrderId = orderId ?? _parseOrderId(data);
    final resolvedDeliveryId = deliveryId ?? data['delivery_id']?.toString();

    if (type == 'admin_broadcast') {
      await _openRoute(AppRoutes.notifications);
      return;
    }

    if (user.isAdmin) {
      await AuthService.instance.rejectAdminMobileAccess();
      await _openRoute(AppRoutes.login);
      return;
    }

    if (user.isDriver) {
      if (type.startsWith('driver_subscription_')) {
        await _openRoute(AppRoutes.driverSubscriptions);
        return;
      }
      if (resolvedDeliveryId != null && resolvedDeliveryId.isNotEmpty) {
        await _openDriverJob(resolvedDeliveryId);
        return;
      }
    }

    if (user.isCustomer && resolvedOrderId != null) {
      if (_customerOrderTypes.contains(type) || type.isNotEmpty) {
        await _openCustomerOrderTrack(resolvedOrderId);
        return;
      }
    }

    if (resolvedOrderId != null) {
      if (user.isCustomer) {
        await _openCustomerOrderTrack(resolvedOrderId);
        return;
      }
    }

    await _openRoute(AppRoutes.notifications);
  }

  /// ينتظر حتى يكتمل السبلاش ويصبح [MainShell] جاهزاً (فتح من إشعار النظام).
  static Future<void> waitUntilReady() async {
    for (var attempt = 0; attempt < 120; attempt++) {
      if (Get.key.currentState == null) {
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }

      if (!AuthService.instance.isLoggedIn) return;

      final route = Get.currentRoute;
      if (route == AppRoutes.main) return;
      if (Get.isRegistered<MainShellController>()) return;

      if (route != AppRoutes.splash && route != AppRoutes.onboarding) return;

      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  static void _popToMainShell() {
    if (Get.isSnackbarOpen == true) {
      Get.closeAllSnackbars();
    }

    if (Get.currentRoute == AppRoutes.main) return;

    final navigator = Get.key.currentState;
    if (navigator == null) return;

    Get.until((route) {
      final name = route.settings.name;
      return name == AppRoutes.main || route.isFirst;
    });
  }

  static Future<void> _ensureMainShell() async {
    await waitUntilReady();
    _popToMainShell();

    if (Get.currentRoute != AppRoutes.main && AuthService.instance.isLoggedIn) {
      await Get.offAllNamed(AppRoutes.main);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  static Future<void> _openRoute(String route, {dynamic arguments}) async {
    await _ensureMainShell();
    await Get.toNamed(route, arguments: arguments);
  }

  static Future<void> _switchMainTab(int tabIndex) async {
    await _ensureMainShell();

    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().setIndex(tabIndex);
    }
  }

  static int? _parseOrderId(Map<String, dynamic> data) {
    final raw = data['order_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static Future<void> _openDriverJob(String deliveryId) async {
    await _switchMainTab(0);
    await Get.toNamed(AppRoutes.driverJobDetail, arguments: deliveryId);
  }

  /// فتح تفاصيل الطلب حسب دور المستخدم الحالي (من بطاقة سعر/طلب).
  static Future<void> openOrderForCurrentUser(int orderId) {
    return openFromPayload(
      type: '',
      data: {'order_id': orderId},
      orderId: orderId,
    );
  }

  static Future<void> openDeliveryForCurrentUser(String deliveryId) {
    return openFromPayload(
      type: 'driver_delivery_assigned',
      data: {'delivery_id': deliveryId},
      deliveryId: deliveryId,
    );
  }

  static Future<void> _openCustomerOrderTrack(int orderId) async {
    try {
      final order = await OrderRepository.instance.fetchOrderById(orderId);
      await _openRoute(AppRoutes.orderTrack, arguments: order);
    } catch (_) {
      await _openRoute(AppRoutes.myOrders);
    }
  }
}
