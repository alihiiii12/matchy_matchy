import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminCouponsController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnInt();
  final coupons = <Map<String, dynamic>>[].obs;
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
      final res = await ApiClient.instance.getJson('/admin/coupons');
      final list = res.data!['data'] as List<dynamic>;
      coupons.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadCouponsFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(int id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(AppRoutes.adminCouponForm);
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> coupon) async {
    final saved = await Get.toNamed(AppRoutes.adminCouponForm, arguments: coupon);
    if (saved == true) await load();
  }

  Future<void> deleteCoupon(Map<String, dynamic> coupon) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteCoupon),
        content: Text(AppStrings.deleteCouponConfirm.replaceFirst('{name}', coupon['name'] as String? ?? '')),
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

    final id = coupon['id'] as int;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/coupons/$id');
      _showMessage(AppStrings.couponDeleted, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminCouponsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCouponsController());
  }
}
