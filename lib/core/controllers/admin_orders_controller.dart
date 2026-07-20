import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/services/admin_orders_pdf_exporter.dart';
import 'package:matchy_matchy/core/services/pdf_file_saver.dart';
import 'package:matchy_matchy/core/utils/order_sort.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminOrdersController extends GetxController {
  final loading = true.obs;
  final archiving = false.obs;
  final orders = <Map<String, dynamic>>[].obs;
  final error = RxnString();
  final highlightOrderId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading.value = true;
      error.value = null;
    }
    try {
      final res = await ApiClient.instance.getJson('/admin/orders');
      final list = res.data!['data'] as List<dynamic>;
      orders.value = OrderSort.sortAdminOrders(list.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل الطلبات');
    } finally {
      if (!silent) {
        loading.value = false;
      }
    }
  }

  final drivers = <Map<String, dynamic>>[].obs;
  final loadingDrivers = false.obs;

  Future<void> loadDrivers() async {
    if (drivers.isNotEmpty) return;
    loadingDrivers.value = true;
    try {
      final res = await ApiClient.instance.getJson('/admin/drivers');
      final list = res.data!['data'] as List<dynamic>;
      drivers.value = list
          .cast<Map<String, dynamic>>()
          .where((d) {
            final profile = d['driver_profile'] as Map<String, dynamic>?;
            return profile?['subscription_active'] == true && profile?['status'] == 'active';
          })
          .toList();
    } on DioException catch (_) {
      drivers.clear();
    } finally {
      loadingDrivers.value = false;
    }
  }

  Future<void> assignDriver(Map<String, dynamic> order) async {
    await loadDrivers();
    if (drivers.isEmpty) {
      _showMessage(AppStrings.noDriversAvailable, success: false);
      return;
    }

    final selectedId = RxnInt(drivers.first['id'] as int?);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.assignDriver),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (loadingDrivers.value) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return DropdownButtonFormField<int>(
              value: selectedId.value,
              decoration: InputDecoration(labelText: AppStrings.selectDriver),
              items: drivers
                  .map(
                    (d) => DropdownMenuItem(
                      value: d['id'] as int,
                      child: Text('${d['name']} — ${d['phone'] ?? ''}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => selectedId.value = v,
            );
          }),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () {
              if (selectedId.value == null) {
                _showMessage(AppStrings.selectDriverFirst, success: false);
                return;
              }
              Get.back(result: true);
            },
            child: Text(AppStrings.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || selectedId.value == null) return;

    try {
      await ApiClient.instance.postJson(
        '/admin/orders/${order['id']}/assign-driver',
        data: {'driver_id': selectedId.value},
      );
      _showMessage(AppStrings.driverAssigned, success: true);
      await load(silent: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  Future<void> notifyCustomer(
    Map<String, dynamic> order, {
    required String estimatedTime,
    required double deliveryFee,
  }) async {
    if (isDeliveryTimeSent(order)) {
      _showMessage(AppStrings.deliveryTimeAlreadySent, success: true);
      return;
    }

    try {
      await ApiClient.instance.postJson(
        '/admin/orders/${order['id']}/notify-delivery-time',
        data: {
          'estimated_time': estimatedTime,
          'delivery_fee': deliveryFee,
        },
      );
      _showMessage(AppStrings.deliveryEmailSent, success: true);
      await load(silent: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  Future<void> approvePayment(Map<String, dynamic> order) async {
    try {
      await ApiClient.instance.postJson('/admin/orders/${order['id']}/approve-payment');
      _showMessage(AppStrings.paymentApproved, success: true);
      await load(silent: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  Future<void> confirmRejectOrder(Map<String, dynamic> order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.rejectOrder),
        content: Text(AppStrings.rejectOrderConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.rejectOrder, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await rejectOrder(order);
  }

  Future<void> rejectOrder(Map<String, dynamic> order) async {
    try {
      await ApiClient.instance.postJson('/admin/orders/${order['id']}/reject-order');
      _showMessage(AppStrings.orderRejected, success: true);
      await load(silent: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  void focusOrder(int orderId) {
    highlightOrderId.value = orderId;
  }

  void openDriverTracking(Map<String, dynamic> order) {
    final id = order['id'] as int?;
    if (id == null) return;
    Get.toNamed(AppRoutes.adminDeliveryTracking, arguments: id);
  }

  void openCustomerLocation(Map<String, dynamic> order) => openDriverTracking(order);

  Future<void> confirmDriverDelivery(Map<String, dynamic> order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.adminConfirmDelivered),
        content: Text(AppStrings.adminConfirmDeliveredConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.adminConfirmDelivered, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.instance.postJson('/admin/orders/${order['id']}/confirm-delivered');
      highlightOrderId.value = null;
      _showMessage(AppStrings.orderDeliveredConfirmed, success: true);
      await load(silent: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    }
  }

  void showPaymentProof(String url) {
    final resolved = CatalogMeta.resolveImageUrl(url);
    if (resolved == null || resolved.isEmpty) {
      _showMessage('تعذر عرض إثبات الدفع', success: false);
      return;
    }
    final height = Get.height * 0.7;
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              AppBar(
                title: Text(AppStrings.viewPaymentProof),
                automaticallyImplyLeading: false,
                actions: [IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close))],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(resolved, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showDeliveryTimeDialog(Map<String, dynamic> order) async {
    if (isDeliveryTimeSent(order)) {
      _showMessage(AppStrings.deliveryTimeAlreadySent, success: true);
      return;
    }

    final delivery = order['delivery'] as Map<String, dynamic>?;
    final initialTime = delivery?['estimated_time'] as String? ?? '';
    final initialFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;

    final result = await Get.dialog<_DeliveryNotifyData>(
      _DeliveryTimeDialog(
        initialTime: initialTime,
        initialDeliveryFee: initialFee,
      ),
      barrierDismissible: false,
    );

    if (result == null) return;
    await notifyCustomer(
      order,
      estimatedTime: result.estimatedTime,
      deliveryFee: result.deliveryFee,
    );
  }

  Future<void> archiveOrders() async {
    if (archiving.value) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.archiveOrders),
        content: Text(AppStrings.archiveOrdersConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.archiveOrders, style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    archiving.value = true;
    try {
      final res = await ApiClient.instance.getJson('/admin/orders', query: {'all': '1'});
      final list = (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
      if (list.isEmpty) {
        _showMessage(AppStrings.noOrdersYet, success: false);
        return;
      }

      final savedPath = await AdminOrdersPdfExporter.exportAndSave(list);
      await PdfFileSaver.openSavedPdf(savedPath);
      final fileName = savedPath.split(Platform.pathSeparator).last;
      _showMessage('${AppStrings.ordersArchiveSaved}\n$fileName', success: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } on PdfSaveException catch (e) {
      _showMessage(e.message, success: false);
    } catch (_) {
      _showMessage(AppStrings.archiveOrdersFailed, success: false);
    } finally {
      archiving.value = false;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  static bool isDeliveryTimeSent(Map<String, dynamic> order) {
    final delivery = order['delivery'] as Map<String, dynamic>?;
    if (delivery?['delivery_time_sent'] == true) return true;
    final notifiedAt = delivery?['delivery_time_emailed_at'];
    return notifiedAt != null && notifiedAt.toString().isNotEmpty;
  }
}

class _DeliveryNotifyData {
  const _DeliveryNotifyData({
    required this.estimatedTime,
    required this.deliveryFee,
  });

  final String estimatedTime;
  final double deliveryFee;
}

class _DeliveryTimeDialog extends StatefulWidget {
  const _DeliveryTimeDialog({
    required this.initialTime,
    required this.initialDeliveryFee,
  });

  final String initialTime;
  final double initialDeliveryFee;

  @override
  State<_DeliveryTimeDialog> createState() => _DeliveryTimeDialogState();
}

class _DeliveryTimeDialogState extends State<_DeliveryTimeDialog> {
  late final TextEditingController _timeController;
  late final TextEditingController _feeController;
  String? _timeError;
  String? _feeError;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.initialTime);
    _feeController = TextEditingController(
      text: widget.initialDeliveryFee.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _timeController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _submit() {
    final time = _timeController.text.trim();
    final feeText = _feeController.text.trim().replaceAll(',', '.');
    final fee = double.tryParse(feeText);

    setState(() {
      _timeError = time.isEmpty ? AppStrings.deliveryTimeRequired : null;
      _feeError = fee == null ? AppStrings.deliveryFeeRequired : null;
    });

    if (time.isEmpty || fee == null) return;

    Get.back(
      result: _DeliveryNotifyData(
        estimatedTime: time,
        deliveryFee: fee,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.setDeliveryTime),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.deliveryTime, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _timeController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'مثال: غداً 3-5 مساءً',
                errorText: _timeError,
              ),
              onChanged: (_) {
                if (_timeError != null) setState(() => _timeError = null);
              },
            ),
            const SizedBox(height: 16),
            Text(AppStrings.deliveryFee, style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: AppStrings.enterDeliveryFee,
                suffixText: CurrencyFormatter.symbol,
                errorText: _feeError,
              ),
              onChanged: (_) {
                if (_feeError != null) setState(() => _feeError = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(AppStrings.cancel)),
        TextButton(onPressed: _submit, child: Text(AppStrings.sendEmail)),
      ],
    );
  }
}

class AdminOrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminOrdersController());
  }
}
