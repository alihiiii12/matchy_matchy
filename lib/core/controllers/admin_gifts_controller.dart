import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminGiftsController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnInt();
  final gifts = <Map<String, dynamic>>[].obs;
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
      final res = await ApiClient.instance.getJson('/admin/gifts');
      gifts.value = (res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.adminGiftsLoadFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(int id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(AppRoutes.adminGiftForm);
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> gift) async {
    final saved = await Get.toNamed(AppRoutes.adminGiftForm, arguments: gift);
    if (saved == true) await load();
  }

  Future<void> deleteGift(Map<String, dynamic> gift) async {
    final title = gift['title'] as String? ?? '';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteGiftReward),
        content: Text(AppStrings.deleteGiftRewardConfirm.replaceFirst('{title}', title)),
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

    final id = gift['id'] as int;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/gifts/$id');
      ApiClient.instance.invalidateGetCache('/gifts');
      _showMessage(AppStrings.giftRewardDeleted, success: true);
      await load();
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } finally {
      actionLoadingId.value = null;
    }
  }

  String rewardTypeLabel(String? type) {
    switch (type) {
      case 'discount_percent':
        return AppStrings.giftTypeDiscount;
      case 'free_delivery':
        return AppStrings.giftTypeFreeDelivery;
      case 'free_product':
        return AppStrings.giftTypeFreeProduct;
      default:
        return AppStrings.giftTypeCustom;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }
}

class AdminGiftsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminGiftsController());
  }
}
