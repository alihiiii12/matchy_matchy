import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/id_photo_viewer.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminDriversController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnInt();
  final drivers = <Map<String, dynamic>>[].obs;
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
      final res = await ApiClient.instance.getJson('/admin/drivers');
      final list = res.data!['data'] as List<dynamic>;
      drivers.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل السائقين');
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(int driverId) => actionLoadingId.value == driverId;

  Future<void> renewSubscription(Map<String, dynamic> driver) async {
    final monthsController = TextEditingController(text: '12');
    final amountController = TextEditingController();
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.renewSubscription),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: AppStrings.subscriptionMonths),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppStrings.driverSubscriptionAmountPaid,
                suffixText: AppStrings.currencySymbol,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.renewSubscription)),
        ],
      ),
    );

    if (confirmed != true) return;

    final months = int.tryParse(monthsController.text.trim());
    if (months == null || months < 1) {
      _showMessage('أدخل مدة صحيحة', success: false);
      return;
    }

    final payload = <String, dynamic>{'subscription_months': months};
    final amount = double.tryParse(amountController.text.trim());
    if (amount != null && amount >= 0) {
      payload['subscription_amount_paid'] = amount;
    }

    await _runAction(
      driverId: driver['id'] as int,
      request: () => ApiClient.instance.postJson('/admin/drivers/${driver['id']}/renew', data: payload),
      successMessage: AppStrings.subscriptionRenewed,
    );
  }

  Future<void> resetDriverPassword(Map<String, dynamic> driver) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.resetDriverPassword),
        content: const Text('سيتم إنشاء كلمة مرور جديدة واستبدال الحالية. هل تريد المتابعة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.confirm)),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runAction(
      driverId: driver['id'] as int,
      request: () => ApiClient.instance.postJson('/admin/drivers/${driver['id']}/reset-password'),
      successMessage: AppStrings.driverPasswordReset,
    );
  }

  Future<void> copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('${AppStrings.copiedToClipboard}: $label', success: true);
  }

  Future<void> cancelSubscription(Map<String, dynamic> driver) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.cancelSubscription),
        content: Text(AppStrings.cancelDriverSubscriptionConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.cancelSubscription, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runAction(
      driverId: driver['id'] as int,
      request: () => ApiClient.instance.postJson('/admin/drivers/${driver['id']}/cancel'),
      successMessage: AppStrings.subscriptionCancelled,
    );
  }

  Future<void> blockDriver(Map<String, dynamic> driver) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.blockDriver),
        content: Text(AppStrings.blockDriverConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.blockDriver, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runAction(
      driverId: driver['id'] as int,
      request: () => ApiClient.instance.postJson('/admin/drivers/${driver['id']}/block'),
      successMessage: AppStrings.driverBlocked,
    );
  }

  Future<void> deleteDriver(Map<String, dynamic> driver) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.forceDeleteDriver),
        content: Text(AppStrings.forceDeleteDriverConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(AppStrings.forceDeleteDriver, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _runAction(
      driverId: driver['id'] as int,
      request: () => ApiClient.instance.deleteJson('/admin/drivers/${driver['id']}'),
      successMessage: AppStrings.driverDeleted,
    );
  }

  Future<void> _runAction({
    required int driverId,
    required Future<Response<Map<String, dynamic>>> Function() request,
    required String successMessage,
  }) async {
    actionLoadingId.value = driverId;
    try {
      await request();
      _showMessage(successMessage, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  Future<void> editDriver(Map<String, dynamic> driver) async {
    final updated = await Get.toNamed(AppRoutes.adminEditDriver, arguments: driver);
    if (updated == true) {
      _showMessage(AppStrings.driverUpdated, success: true);
      await load();
    }
  }

  Future<void> showIdPhoto(Map<String, dynamic> driver, {required bool front}) => IdPhotoViewer.showAdmin(
        resource: 'drivers',
        userId: driver['id'] as int,
        front: front,
        onError: (message) => _showMessage(message, success: false),
      );

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminDriversBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminDriversController());
  }
}
