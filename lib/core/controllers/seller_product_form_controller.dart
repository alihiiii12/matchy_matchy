import 'dart:io';

import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/services/delivery_service.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class SellerProductFormController extends GetxController {
  SellerProductFormController({Map<String, dynamic>? product})
      : editingProduct = product,
        isEditing = product != null;

  final Map<String, dynamic>? editingProduct;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();

  final submitting = false.obs;
  final imageFile = Rxn<File>();
  final imageFileName = RxnString();
  final selectedCategoryId = RxnString();
  final selectedSubCategoryId = RxnString();
  final selectedGovernorateId = RxnString();
  final categories = <ShopCategory>[].obs;
  final subCategories = <SubCategory>[].obs;
  final governorates = <Map<String, dynamic>>[].obs;

  String? get existingImageUrl =>
      CatalogMeta.resolveImageUrl(editingProduct?['image_url'] as String?);

  @override
  void onInit() {
    super.onInit();
    _loadCategories();
    _loadGovernorates();
    if (isEditing) {
      nameController.text = editingProduct!['name'] as String? ?? '';
      priceController.text = '${editingProduct!['price'] ?? ''}';
      selectedCategoryId.value = editingProduct!['category_id'] as String?;
      selectedSubCategoryId.value = editingProduct!['sub_category_id'] as String?;
      selectedGovernorateId.value = editingProduct!['seller_governorate_id'] as String?;
      _refreshSubCategories();
    }
  }

  Future<void> _loadCategories() async {
    await CatalogRepository.instance.load();
    categories.assignAll(CategoryCatalog.categories);
    if (selectedCategoryId.value != null) {
      _refreshSubCategories();
    }
  }

  Future<void> _loadGovernorates() async {
    try {
      final res = await ApiClient.instance.getJson('/governorates');
      final list = (res.data?['data'] as List?) ?? [];
      if (list.isNotEmpty) {
        governorates.assignAll(list.cast<Map<String, dynamic>>());
        return;
      }
    } catch (_) {}

    governorates.assignAll(
      DeliveryService.governorates
          .map((g) => {'id': g.id, 'name': g.name})
          .toList(),
    );
  }

  void onCategoryChanged(String? value) {
    selectedCategoryId.value = value;
    selectedSubCategoryId.value = null;
    _refreshSubCategories();
  }

  void _refreshSubCategories() {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) {
      subCategories.clear();
      return;
    }
    final category = categories.firstWhereOrNull((c) => c.id == categoryId);
    subCategories.assignAll(category?.subCategories ?? []);
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    imageFile.value = File(path);
    imageFileName.value = result.files.single.name;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedCategoryId.value == null || selectedSubCategoryId.value == null) {
      _showMessage(AppStrings.selectSubCategory, success: false);
      return;
    }

    if (selectedGovernorateId.value == null) {
      _showMessage('يرجى اختيار المحافظة', success: false);
      return;
    }

    if (!isEditing && imageFile.value == null) {
      _showMessage(AppStrings.productImageRequired, success: false);
      return;
    }

    submitting.value = true;
    try {
      final fields = <String, dynamic>{
        'name': nameController.text.trim(),
        'category_id': selectedCategoryId.value!,
        'sub_category_id': selectedSubCategoryId.value!,
        'seller_governorate_id': selectedGovernorateId.value!,
        'price': double.parse(priceController.text.trim()),
      };

      Map<String, MultipartFile>? files;
      if (imageFile.value != null) {
        files = {
          'image': await MultipartFile.fromFile(
            imageFile.value!.path,
            filename: imageFileName.value,
          ),
        };
      }

      String successMessage;
      if (isEditing) {
        final res = await ApiClient.instance.postMultipart(
          '/seller/products/${editingProduct!['id']}/update-request',
          fields: fields,
          files: files,
        );
        successMessage = res.data?['message'] as String? ?? AppStrings.productUpdateSubmitted;
      } else {
        final res = await ApiClient.instance.postMultipart(
          '/seller/products',
          fields: fields,
          files: files!,
        );
        successMessage = res.data?['message'] as String? ?? AppStrings.productSubmittedForReview;
      }

      await _showResultDialog(
        title: AppStrings.submitSuccessTitle,
        message: successMessage,
        success: true,
      );

      Get.back(result: true);
    } on DioException catch (e) {
      await _showResultDialog(
        title: AppStrings.submitFailedTitle,
        message: apiFriendlyError(e, fallback: AppStrings.productSubmitFailed),
        success: false,
      );
    } catch (_) {
      await _showResultDialog(
        title: AppStrings.submitFailedTitle,
        message: AppStrings.productSubmitFailed,
        success: false,
      );
    } finally {
      submitting.value = false;
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
  }) async {
    await Get.dialog<void>(
      AlertDialog(
        icon: Icon(
          success ? Icons.check_circle_outline : Icons.error_outline,
          color: success ? AppColors.success : AppColors.error,
          size: 40,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    priceController.dispose();
    super.onClose();
  }
}

class SellerProductFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SellerProductFormController(product: Get.arguments as Map<String, dynamic>?));
  }
}
