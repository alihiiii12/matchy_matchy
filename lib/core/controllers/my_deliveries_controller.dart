import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/confirm_receipt_points.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class MyDeliveriesController extends GetxController {
  MyDeliveriesController({this.embedded = false});

  final bool embedded;
  final active = <DeliveryOrder>[].obs;
  final completed = <DeliveryOrder>[].obs;
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!AuthService.instance.isLoggedIn) {
      active.clear();
      completed.clear();
      error.value = null;
      loading.value = false;
      return;
    }

    loading.value = true;
    error.value = null;
    try {
      final all = await DeliveryRepository.instance.fetchDeliveries();
      active.value = all.where((d) => d.status != DeliveryStatus.delivered).toList();
      completed.value = all.where((d) => d.status == DeliveryStatus.delivered).toList();
    } on DioException catch (e) {
      active.clear();
      completed.clear();
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل التوصيلات');
    } catch (_) {
      active.clear();
      completed.clear();
      error.value = 'تعذر تحميل التوصيلات';
    } finally {
      loading.value = false;
    }
  }

  void goToMyOrders() => Get.toNamed(AppRoutes.myOrders);

  void openDelivery(DeliveryOrder delivery) {
    Get.toNamed(AppRoutes.deliveryTracking, arguments: delivery);
  }

  Future<void> confirmReceipt(DeliveryOrder delivery) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.confirmReceipt),
        content: Text(AppStrings.confirmReceiptMessage),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.confirmReceipt, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await DeliveryRepository.instance.confirmReceipt(delivery.id);
      ConfirmReceiptPoints.applyFromResult(
        pointsEarned: result.pointsEarned,
        pointsBalance: result.pointsBalance,
      );
      await load();
      Get.closeAllSnackbars();
      Get.snackbar(
        AppStrings.appName,
        result.message.isNotEmpty ? result.message : AppStrings.receiptConfirmed,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );
      final orderId = delivery.orderId;
      if (orderId.isNotEmpty) {
        Get.toNamed(AppRoutes.rateOrder, arguments: {
          'order_id': int.tryParse(orderId) ?? 0,
          'product_ids': <String>[],
        });
      }
    } on DioException catch (e) {
      Get.closeAllSnackbars();
      Get.snackbar(
        AppStrings.appName,
        apiFriendlyError(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class MyDeliveriesBinding extends Bindings {
  MyDeliveriesBinding({this.embedded = false});

  final bool embedded;

  @override
  void dependencies() {
    Get.put(MyDeliveriesController(embedded: embedded));
  }
}
