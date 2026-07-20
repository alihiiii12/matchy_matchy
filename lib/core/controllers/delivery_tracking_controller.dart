import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/my_deliveries_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/delivery.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/confirm_receipt_points.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class DeliveryTrackingController extends GetxController {
  DeliveryTrackingController(DeliveryOrder initial) {
    delivery.value = initial;
  }

  final delivery = Rxn<DeliveryOrder>();
  final confirming = false.obs;

  bool get canConfirm => delivery.value?.awaitingCustomerConfirmation ?? false;
  bool get showLiveTracking => !canConfirm && delivery.value?.status != DeliveryStatus.delivered;

  Future<void> confirmReceipt() async {
    final current = delivery.value;
    if (current == null || !current.awaitingCustomerConfirmation) return;

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

    confirming.value = true;
    try {
      final result = await DeliveryRepository.instance.confirmReceipt(current.id);
      delivery.value = result.delivery;
      ConfirmReceiptPoints.applyFromResult(
        pointsEarned: result.pointsEarned,
        pointsBalance: result.pointsBalance,
      );
      _refreshDeliveriesList();
      _showMessage(
        result.message.isNotEmpty ? result.message : AppStrings.receiptConfirmed,
        success: true,
      );
      final orderId = current.orderId;
      if (orderId.isNotEmpty) {
        Get.toNamed(
          AppRoutes.rateOrder,
          arguments: {
            'order_id': int.tryParse(orderId) ?? 0,
            'product_ids': <String>[],
          },
        );
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      confirming.value = false;
    }
  }

  void _refreshDeliveriesList() {
    for (final tag in ['my_deliveries_true', 'my_deliveries_false']) {
      if (Get.isRegistered<MyDeliveriesController>(tag: tag)) {
        Get.find<MyDeliveriesController>(tag: tag).load();
      }
    }
    if (Get.isRegistered<MyDeliveriesController>()) {
      Get.find<MyDeliveriesController>().load();
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class DeliveryTrackingBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    if (args is DeliveryOrder) {
      Get.put(DeliveryTrackingController(args));
    }
  }
}
