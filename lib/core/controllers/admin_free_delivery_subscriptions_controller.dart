import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminFreeDeliverySubscriptionsController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnInt();
  final subscriptions = <Map<String, dynamic>>[].obs;
  final error = RxnString();

  static final _dateFormat = DateFormat('yyyy-MM-dd', 'ar');

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/free-delivery-subscriptions');
      final list = res.data!['data'] as List<dynamic>;
      subscriptions.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadFreeDeliverySubscriptionsFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(int id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(AppRoutes.adminFreeDeliverySubscriptionForm);
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> subscription) async {
    final saved = await Get.toNamed(AppRoutes.adminFreeDeliverySubscriptionForm, arguments: subscription);
    if (saved == true) await load();
  }

  Future<void> deleteSubscription(Map<String, dynamic> subscription) async {
    final brand = subscription['brand_name'] as String? ?? '';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteFreeDeliverySubscription),
        content: Text(AppStrings.deleteFreeDeliverySubscriptionConfirm.replaceFirst('{brand}', brand)),
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

    final id = subscription['id'] as int;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/free-delivery-subscriptions/$id');
      await CatalogRepository.instance.reload();
      _showMessage(AppStrings.freeDeliverySubscriptionDeleted, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return _dateFormat.format(date.toLocal());
  }

  String formatAmount(num? amount) {
    if (amount == null || amount <= 0) return '—';
    return CurrencyFormatter.format(amount);
  }

  String statusLabel(Map<String, dynamic> subscription) {
    if (subscription['is_active'] == true) return AppStrings.freeDeliverySubscriptionActive;
    if (subscription['is_upcoming'] == true) return AppStrings.freeDeliverySubscriptionUpcoming;
    return AppStrings.freeDeliverySubscriptionExpired;
  }

  Color statusColor(Map<String, dynamic> subscription) {
    if (subscription['is_active'] == true) return AppColors.success;
    if (subscription['is_upcoming'] == true) return AppColors.accent;
    return AppColors.error;
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminFreeDeliverySubscriptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminFreeDeliverySubscriptionsController());
  }
}
