import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/home_advertisement_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminHomeAdvertisementsController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnString();
  final ads = <Map<String, dynamic>>[].obs;
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
      final res = await ApiClient.instance.getJson('/admin/home-advertisements');
      final body = res.data!;
      final list = body['data'] as List<dynamic>? ?? [];
      ads.value = list.cast<Map<String, dynamic>>();
      if (body['setup_required'] == true && body['message'] is String) {
        error.value = body['message'] as String;
      }
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadHomeAdvertisementsFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(AppRoutes.adminHomeAdvertisementForm);
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> ad) async {
    final saved = await Get.toNamed(
      AppRoutes.adminHomeAdvertisementForm,
      arguments: {'ad': ad},
    );
    if (saved == true) await load();
  }

  Future<void> deleteAd(Map<String, dynamic> ad) async {
    final title = ad['title'] as String? ?? '';
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteHomeAdvertisement),
        content: Text(AppStrings.deleteHomeAdvertisementConfirm.replaceFirst('{title}', title)),
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

    final id = ad['id'] as String;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/home-advertisements/$id');
      await HomeAdvertisementRepository.instance.reload();
      _showMessage(AppStrings.homeAdvertisementDeleted, success: true);
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

class AdminHomeAdvertisementsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminHomeAdvertisementsController());
  }
}
