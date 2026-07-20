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

class AdminSubCategoriesController extends GetxController {
  AdminSubCategoriesController({required this.category});

  final Map<String, dynamic> category;

  final loading = true.obs;
  final actionLoadingId = RxnString();
  final subCategories = <Map<String, dynamic>>[].obs;
  final error = RxnString();

  String get categoryId => category['id'] as String;
  String get categoryName => category['name'] as String? ?? '';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/categories/$categoryId/sub-categories');
      final data = res.data!['data'] as Map<String, dynamic>;
      final list = data['sub_categories'] as List<dynamic>;
      subCategories.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadSubCategoriesFailed);
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingId.value == id;

  Future<void> openCreateForm() async {
    final saved = await Get.toNamed(
      AppRoutes.adminSubCategoryForm,
      arguments: {'category': category},
    );
    if (saved == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> subCategory) async {
    final saved = await Get.toNamed(
      AppRoutes.adminSubCategoryForm,
      arguments: {'category': category, 'subCategory': subCategory},
    );
    if (saved == true) await load();
  }

  Future<void> deleteSubCategory(Map<String, dynamic> subCategory) async {
    final productsCount = subCategory['products_count'] as int? ?? 0;
    if (productsCount > 0) {
      _showMessage(AppStrings.cannotDeleteSubCategoryHasProducts, success: false);
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteSubCategory),
        content: Text(AppStrings.deleteSubCategoryConfirm.replaceFirst('{name}', subCategory['name'] as String? ?? '')),
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

    final id = subCategory['id'] as String;
    actionLoadingId.value = id;
    try {
      await ApiClient.instance.deleteJson('/admin/sub-categories/$id');
      await CatalogRepository.instance.reload();
      _showMessage(AppStrings.subCategoryDeleted, success: true);
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

class AdminSubCategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminSubCategoriesController(category: Get.arguments as Map<String, dynamic>));
  }
}
