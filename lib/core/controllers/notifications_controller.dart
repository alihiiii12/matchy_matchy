import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/my_orders_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/app_notification.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/services/notification_service.dart';
import 'package:matchy_matchy/core/utils/confirm_receipt_points.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class NotificationsController extends GetxController {
  NotificationsController({this.notificationService});

  final NotificationService? notificationService;
  final confirmingIds = <String>{}.obs;
  final _confirmStateVersion = 0.obs;
  final _confirmedNotificationIds = <String>{};
  final _completedOrderIds = <int>{};

  NotificationService get service => notificationService ?? NotificationService.instance;

  @override
  void onInit() {
    super.onInit();
    service.refresh(pushNew: false).then((_) => syncConfirmableStates());
  }

  @override
  Future<void> refresh() async {
    await service.refresh(pushNew: false);
    await syncConfirmableStates();
  }

  Future<void> markRead(String id) => service.markRead(id);

  Future<void> markAllRead() => service.markAllRead();

  final deletingIds = <String>{}.obs;

  bool isDeleting(String id) => deletingIds.contains(id);

  Future<void> deleteNotification(AppNotificationItem notification) async {
    if (isDeleting(notification.id)) return;

    deletingIds.add(notification.id);
    deletingIds.refresh();
    try {
      await service.deleteNotification(notification.id);
      _confirmedNotificationIds.remove(notification.id);
      _confirmStateVersion.value++;
      _showMessage(AppStrings.notificationDeleted, success: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage(AppStrings.deleteNotificationFailed, success: false);
    } finally {
      deletingIds.remove(notification.id);
      deletingIds.refresh();
    }
  }

  Future<void> deleteAllNotifications() async {
    if (service.items.isEmpty) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteAllNotifications),
        content: Text(AppStrings.deleteAllNotificationsConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.deleteAllNotifications();
      _confirmedNotificationIds.clear();
      _completedOrderIds.clear();
      _confirmStateVersion.value++;
      _showMessage(AppStrings.allNotificationsDeleted, success: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage(AppStrings.deleteAllNotificationsFailed, success: false);
    }
  }

  Future<void> openNotification(AppNotificationItem notification) => service.openNotification(notification);

  Future<void> onNotificationTap(AppNotificationItem notification) async {
    await service.handleNotificationTap(notification: notification);
  }

  bool isConfirming(String notificationId) {
    confirmingIds.length;
    return confirmingIds.contains(notificationId);
  }

  int get confirmStateVersion => _confirmStateVersion.value;

  bool canShowConfirmButton(AppNotificationItem notification) {
    _confirmStateVersion.value;
    if (!notification.canConfirmArrival) return false;
    if (_confirmedNotificationIds.contains(notification.id)) return false;
    final orderId = notification.orderId;
    if (orderId != null && _completedOrderIds.contains(orderId)) return false;
    return true;
  }

  bool isArrivalConfirmed(AppNotificationItem notification) {
    _confirmStateVersion.value;
    if (_confirmedNotificationIds.contains(notification.id)) return true;
    final orderId = notification.orderId;
    return orderId != null && _completedOrderIds.contains(orderId);
  }

  Future<void> syncConfirmableStates() async {
    final pending = service.items.where(
      (n) => n.canConfirmArrival && n.orderId != null && !_confirmedNotificationIds.contains(n.id),
    );

    for (final notification in pending) {
      final orderId = notification.orderId!;
      if (_completedOrderIds.contains(orderId)) continue;

      try {
        final order = await OrderRepository.instance.fetchOrderById(orderId);
        if (order.status != 'awaiting_receipt') {
          _completedOrderIds.add(orderId);
        }
      } catch (_) {}
    }

    _confirmStateVersion.value++;
  }

  Future<void> confirmArrival(AppNotificationItem notification) async {
    if (!canShowConfirmButton(notification) || isConfirming(notification.id)) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.confirmArrival),
        content: Text(AppStrings.confirmReceiptMessage),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.confirmArrival, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    confirmingIds.add(notification.id);
    confirmingIds.refresh();

    try {
      final deliveryId = await _resolveDeliveryId(notification);
      if (deliveryId == null || deliveryId.isEmpty) {
        _showMessage('تعذر العثور على بيانات التوصيل', success: false);
        return;
      }

      final result = await DeliveryRepository.instance.confirmReceipt(deliveryId);
      ConfirmReceiptPoints.applyFromResult(
        pointsEarned: result.pointsEarned,
        pointsBalance: result.pointsBalance,
      );
      _markAsCompleted(notification);
      await service.markRead(notification.id);
      await service.refresh(pushNew: false);

      if (Get.isRegistered<MyOrdersController>()) {
        await Get.find<MyOrdersController>().load();
      }

      _showMessage(AppStrings.confirmArrivalSuccess, success: true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        _markAsCompleted(notification);
        await service.refresh(pushNew: false);
        _showMessage(AppStrings.arrivalAlreadyConfirmed, success: true);
      } else {
        _showMessage(apiFriendlyError(e), success: false);
      }
    } catch (_) {
      _showMessage('تعذر تأكيد الاستلام', success: false);
    } finally {
      confirmingIds.remove(notification.id);
      confirmingIds.refresh();
    }
  }

  void _markAsCompleted(AppNotificationItem notification) {
    _confirmedNotificationIds.add(notification.id);
    final orderId = notification.orderId;
    if (orderId != null) {
      _completedOrderIds.add(orderId);
    }
    _confirmStateVersion.value++;
  }

  Future<String?> _resolveDeliveryId(AppNotificationItem notification) async {
    final direct = notification.deliveryId;
    if (direct != null && direct.isNotEmpty) return direct;

    final orderId = notification.orderId;
    if (orderId == null) return null;

    final order = await OrderRepository.instance.fetchOrderById(orderId);
    return order.delivery?.id;
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NotificationsController());
  }
}
