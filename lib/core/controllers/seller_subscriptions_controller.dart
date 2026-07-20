import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class SellerSubscriptionsController extends GetxController {
  final loading = true.obs;
  final error = RxnString();
  final accountSubscription = Rxn<Map<String, dynamic>>();
  final otherSubscriptions = <Map<String, dynamic>>[].obs;

  static final _dateFormat = DateFormat('yyyy/MM/dd', 'ar');

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/seller/subscriptions');
      final data = res.data!['data'] as Map<String, dynamic>;
      accountSubscription.value = data['account'] as Map<String, dynamic>?;
      otherSubscriptions.assignAll(
        (data['others'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadSellerSubscriptionsFailed);
    } finally {
      loading.value = false;
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
    final label = subscription['status_label'] as String?;
    if (label != null && label.isNotEmpty) return label;

    if (subscription['is_active'] == true) return AppStrings.freeDeliverySubscriptionActive;
    if (subscription['is_upcoming'] == true) return AppStrings.freeDeliverySubscriptionUpcoming;
    return AppStrings.freeDeliverySubscriptionExpired;
  }

  Color statusColor(Map<String, dynamic> subscription) {
    if (subscription['is_active'] == true) return AppColors.success;
    if (subscription['is_upcoming'] == true) return AppColors.accent;
    return AppColors.error;
  }
}

class SellerSubscriptionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SellerSubscriptionsController());
  }
}
