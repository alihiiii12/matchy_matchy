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
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminCategoryFormController extends GetxController {
  AdminCategoryFormController({Map<String, dynamic>? category})
      : editingCategory = category,
        isEditing = category != null;

  final Map<String, dynamic>? editingCategory;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final colorController = TextEditingController(text: '#2E3192');

  final submitting = false.obs;
  final imageFile = Rxn<File>();
  final imageFileName = RxnString();
  final imageBytes = Rxn<Uint8List>();

  String? get existingImageUrl =>
      CatalogMeta.resolveImageUrl(editingCategory?['image_url'] as String?);

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      nameController.text = editingCategory!['name'] as String? ?? '';
      descriptionController.text = editingCategory!['description'] as String? ?? '';
      colorController.text = editingCategory!['color_hex'] as String? ?? '#2E3192';
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
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}$name');
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

    if (!isEditing && imageFile.value == null) {
      _showMessage(AppStrings.categoryImageRequired, success: false);
      return;
    }

    submitting.value = true;
    try {
      final fields = <String, dynamic>{
        'name': nameController.text.trim(),
        'color_hex': colorController.text.trim(),
      };
      final description = descriptionController.text.trim();
      if (description.isNotEmpty) {
        fields['description'] = description;
      }

      Map<String, MultipartFile>? files;
      final file = imageFile.value;
      if (file != null) {
        files = {
          'image': await MultipartImage.fromPickedFile(
            file: file,
            filename: imageFileName.value,
            bytes: imageBytes.value,
          ),
        };
      }

      if (isEditing) {
        await ApiClient.instance.patchMultipart(
          '/admin/categories/${editingCategory!['id']}',
          fields: fields,
          files: files,
        );
      } else {
        await ApiClient.instance.postMultipart(
          '/admin/categories',
          fields: fields,
          files: files,
        );
      }

      await CatalogRepository.instance.reload();

      await Get.dialog<void>(
        AlertDialog(
          title: Text(AppStrings.savedSuccessfully),
          content: Text(isEditing ? AppStrings.categoryUpdated : AppStrings.categoryCreated),
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
      _showMessage(AppStrings.saveCategoryFailed, success: false);
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
    nameController.dispose();
    descriptionController.dispose();
    colorController.dispose();
    super.onClose();
  }
}

class AdminCategoryFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCategoryFormController(category: Get.arguments as Map<String, dynamic>?));
  }
}
