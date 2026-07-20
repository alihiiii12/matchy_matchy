import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/multipart_image.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/repositories/home_slide_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminHomeSlideFormController extends GetxController {
  AdminHomeSlideFormController({required Map<String, dynamic> args})
      : slideType = args['type'] as String? ?? 'category',
        editingSlide = args['slide'] as Map<String, dynamic>?,
        isEditing = args['slide'] != null;

  final String slideType;
  final Map<String, dynamic>? editingSlide;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();

  final submitting = false.obs;
  final loadingCategories = false.obs;
  final loadingBrands = false.obs;
  final imageFile = Rxn<File>();
  final imageFileName = RxnString();
  final imageBytes = Rxn<Uint8List>();
  final categories = <Map<String, dynamic>>[].obs;
  final sellerBrands = <String>[].obs;
  final selectedCategoryId = RxnString();
  final selectedBrandName = RxnString();

  String? get existingImageUrl =>
      CatalogMeta.resolveImageUrl(editingSlide?['image_url'] as String?);

  bool get isCategorySlide => slideType == 'category';

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      selectedCategoryId.value = editingSlide!['category_id'] as String?;
      selectedBrandName.value =
          editingSlide!['brand_name'] as String? ?? editingSlide!['title'] as String?;
    }
    if (isCategorySlide) {
      loadCategories();
    } else {
      loadSellerBrands();
    }
  }

  Future<void> loadCategories() async {
    loadingCategories.value = true;
    try {
      await CatalogRepository.instance.reload();
      final res = await ApiClient.instance.getJson('/admin/categories');
      final list = res.data!['data'] as List<dynamic>;
      categories.assignAll(list.cast<Map<String, dynamic>>());
      _syncSelectedCategory();
    } catch (_) {
      categories.clear();
      selectedCategoryId.value = null;
    } finally {
      loadingCategories.value = false;
    }
  }

  Future<void> loadSellerBrands() async {
    loadingBrands.value = true;
    try {
      final res = await ApiClient.instance.getJson('/admin/seller-brands');
      final list = res.data!['data'] as List<dynamic>;
      sellerBrands.assignAll(list.map((item) => item.toString()).toList());
      _syncSelectedBrand();
    } catch (_) {
      sellerBrands.clear();
      selectedBrandName.value = null;
    } finally {
      loadingBrands.value = false;
    }
  }

  void _syncSelectedCategory() {
    final selected = selectedCategoryId.value;
    if (selected == null) return;

    final exists = categories.any((category) => category['id'] == selected);
    if (!exists) {
      selectedCategoryId.value = null;
    }
  }

  void _syncSelectedBrand() {
    final selected = selectedBrandName.value;
    if (selected == null) return;

    if (!sellerBrands.contains(selected)) {
      selectedBrandName.value = null;
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final path = picked.path;
    final bytes = picked.bytes;

    if (path != null) {
      imageFile.value = File(path);
    } else if (bytes != null) {
      final name = MultipartImage.resolveFilename(pickedName: picked.name);
      final tempFile = File('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
      await tempFile.writeAsBytes(bytes, flush: true);
      imageFile.value = tempFile;
    } else {
      return;
    }

    imageFileName.value = picked.name;
    imageBytes.value = bytes;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (isCategorySlide && (selectedCategoryId.value == null || selectedCategoryId.value!.isEmpty)) {
      _showMessage(AppStrings.homeSlideCategoryRequired, success: false);
      return;
    }

    if (!isCategorySlide && (selectedBrandName.value == null || selectedBrandName.value!.isEmpty)) {
      _showMessage(AppStrings.homeSlideBrandTitleRequired, success: false);
      return;
    }

    if (!isEditing && imageFile.value == null) {
      _showMessage(AppStrings.homeSlideImageRequired, success: false);
      return;
    }

    submitting.value = true;
    try {
      final fields = <String, dynamic>{
        'type': slideType,
      };

      if (isCategorySlide) {
        fields['category_id'] = selectedCategoryId.value;
      } else {
        fields['brand_name'] = selectedBrandName.value;
      }

      Map<String, MultipartFile>? files;
      if (imageFile.value != null) {
        files = {
          'image': await MultipartImage.fromPickedFile(
            file: imageFile.value!,
            filename: imageFileName.value,
            bytes: imageBytes.value,
          ),
        };
      }

      if (isEditing) {
        await ApiClient.instance.patchMultipart(
          '/admin/home-slides/${editingSlide!['id']}',
          fields: fields,
          files: files,
        );
      } else {
        await ApiClient.instance.postMultipart(
          '/admin/home-slides',
          fields: fields,
          files: files,
        );
      }

      await HomeSlideRepository.instance.reload();

      await Get.dialog<void>(
        AlertDialog(
          title: Text(AppStrings.savedSuccessfully),
          content: Text(isEditing ? AppStrings.homeSlideUpdated : AppStrings.homeSlideCreated),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
          ],
        ),
        barrierDismissible: false,
      );

      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage(AppStrings.saveHomeSlideFailed, success: false);
    } finally {
      submitting.value = false;
    }
  }

  void _showMessage(String message, {required bool success}) {
    showMatchySnackBar(
      message: message,
      type: success ? AppSnackBarType.success : AppSnackBarType.error,
    );
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }
}

class AdminHomeSlideFormBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map<String, dynamic>? ?? {'type': 'category'};
    Get.put(AdminHomeSlideFormController(args: args));
  }
}
