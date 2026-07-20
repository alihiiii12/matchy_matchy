import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response, MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AdminCategoriesController extends GetxController {
  final loading = true.obs;
  final actionLoadingId = RxnString();
  final categories = <Map<String, dynamic>>[].obs;
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
      final res = await ApiClient.instance.getJson('/admin/categories');
      final list = res.data!['data'] as List<dynamic>;
      categories.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadCategoriesFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(AppRoutes.adminCategoryForm);
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> category) async {
    final saved = await Get.toNamed(AppRoutes.adminCategoryForm, arguments: category);
    if (saved == true) await load();
  }

  Future<void> openSubCategories(Map<String, dynamic> category) async {
    final changed = await Get.toNamed(AppRoutes.adminSubCategories, arguments: category);
    if (changed == true) await load();
  }

  Future<void> deleteCategory(Map<String, dynamic> category) async {
    final productsCount = category['products_count'] as int? ?? 0;
    if (productsCount > 0) {
      _showMessage(AppStrings.cannotDeleteCategoryHasProducts, success: false);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteCategory),
        content: Text(AppStrings.deleteCategoryConfirm.replaceFirst('{name}', category['name'] as String? ?? '')),
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

    final id = category['id'] as String;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/categories/$id');
      await CatalogRepository.instance.reload();
      _showMessage(AppStrings.categoryDeleted, success: true);
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

class AdminCategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCategoriesController());
  }
}
