import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/core/utils/order_sort.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminManualInvoicesController extends GetxController {
  final loading = true.obs;
  final actionId = RxnInt();
  final invoices = <Map<String, dynamic>>[].obs;
  final drivers = <Map<String, dynamic>>[].obs;
  final loadingDrivers = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/manual-invoices');
      invoices.value = OrderSort.sortManualInvoices(
        (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل الفواتير اليدوية');
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadDrivers() async {
    loadingDrivers.value = true;
    try {
      final res = await ApiClient.instance.getJson('/admin/drivers');
      final list = (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      drivers.value = list;
    } catch (_) {
      drivers.clear();
    } finally {
      loadingDrivers.value = false;
    }
  }

  Future<void> approve(Map<String, dynamic> invoice) async {
    final subtotalController = TextEditingController(text: '0');
    final feeController = TextEditingController();
    final timeController = TextEditingController();

    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.approveManualInvoice),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subtotalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppStrings.orderPrice),
              ),
              TextField(
                controller: feeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: AppStrings.deliveryFee),
              ),
              TextField(
                controller: timeController,
                decoration: InputDecoration(labelText: AppStrings.expectedDelivery),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.approve)),
        ],
      ),
    );

    if (ok != true) {
      subtotalController.dispose();
      feeController.dispose();
      timeController.dispose();
      return;
    }

    final id = invoice['id'] as int;
    actionId.value = id;
    try {
      final res = await ApiClient.instance.postJson(
        '/admin/manual-invoices/$id/approve',
        data: {
          'subtotal': double.tryParse(subtotalController.text.trim()) ?? 0,
          'delivery_fee': double.tryParse(feeController.text.trim()) ?? 0,
          'estimated_time': timeController.text.trim(),
        },
      );
      _showMessage(res.data?['message'] as String? ?? AppStrings.manualInvoiceApproved, success: true);
      await load();
      final orderId = res.data?['order_id'];
      if (orderId != null) {
        await _offerAssignDriver(orderId as int);
      }
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionId.value = null;
      subtotalController.dispose();
      feeController.dispose();
      timeController.dispose();
    }
  }

  Future<void> _offerAssignDriver(int orderId) async {
    final assign = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.assignDriver),
        content: Text(AppStrings.assignDriverAfterManualInvoice),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.later)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.assignDriver)),
        ],
      ),
    );
    if (assign == true) {
      await assignDriverToOrder(orderId);
    }
  }

  Future<void> assignDriverToOrder(int orderId) async {
    await loadDrivers();
    if (drivers.isEmpty) {
      _showMessage(AppStrings.noDriversAvailable, success: false);
      return;
    }

    final selectedId = RxnInt(drivers.first['id'] as int?);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.assignDriver),
        content: Obx(() => DropdownButtonFormField<int>(
              value: selectedId.value,
              decoration: InputDecoration(labelText: AppStrings.selectDriver),
              items: drivers
                  .map((d) => DropdownMenuItem(value: d['id'] as int, child: Text(d['name'] as String? ?? '')))
                  .toList(),
              onChanged: (v) => selectedId.value = v,
            )),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.assignDriver)),
        ],
      ),
    );

    if (confirmed != true || selectedId.value == null) return;

    try {
      await ApiClient.instance.postJson(
        '/admin/orders/$orderId/assign-driver',
        data: {'driver_id': selectedId.value},
      );
      _showMessage(AppStrings.driverAssigned, success: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  Future<void> reject(Map<String, dynamic> invoice) async {
    final reasonController = TextEditingController();
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.rejectManualInvoice),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(labelText: AppStrings.rejectReasonOptional),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.reject, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) {
      reasonController.dispose();
      return;
    }

    final id = invoice['id'] as int;
    actionId.value = id;
    try {
      await ApiClient.instance.postJson(
        '/admin/manual-invoices/$id/reject',
        data: {'reason': reasonController.text.trim()},
      );
      _showMessage(AppStrings.manualInvoiceRejected, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionId.value = null;
      reasonController.dispose();
    }
  }

  void openOrders() => Get.toNamed(AppRoutes.adminOrders);

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminManualInvoicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminManualInvoicesController());
  }
}
