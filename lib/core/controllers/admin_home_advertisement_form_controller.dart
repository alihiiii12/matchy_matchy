import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/multipart_image.dart';
import 'package:matchy_matchy/core/repositories/home_advertisement_repository.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

class AdminHomeAdvertisementFormController extends GetxController {
  AdminHomeAdvertisementFormController({Map<String, dynamic>? args})
      : editingAd = args?['ad'] as Map<String, dynamic>?,
        isEditing = args?['ad'] != null;

  final Map<String, dynamic>? editingAd;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final titleEnController = TextEditingController();
  final descriptionController = TextEditingController();
  final descriptionEnController = TextEditingController();

  final submitting = false.obs;
  final imageFile = Rxn<File>();
  final imageFileName = RxnString();
  final imageBytes = Rxn<Uint8List>();

  String? get existingImageUrl =>
      CatalogMeta.resolveImageUrl(editingAd?['image_url'] as String?);

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      titleController.text = editingAd!['title'] as String? ?? '';
      titleEnController.text = editingAd!['title_en'] as String? ?? '';
      descriptionController.text = editingAd!['description'] as String? ?? '';
      descriptionEnController.text = editingAd!['description_en'] as String? ?? '';
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

    if (!isEditing && imageFile.value == null) {
      _showMessage(AppStrings.homeAdvertisementImageRequired, success: false);
      return;
    }

    submitting.value = true;
    try {
      final fields = <String, dynamic>{
        'title': titleController.text.trim(),
        'title_en': titleEnController.text.trim(),
        'description': descriptionController.text.trim(),
        'description_en': descriptionEnController.text.trim(),
      };

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
          '/admin/home-advertisements/${editingAd!['id']}',
          fields: fields,
          files: files,
        );
      } else {
        await ApiClient.instance.postMultipart(
          '/admin/home-advertisements',
          fields: fields,
          files: files,
        );
      }

      await HomeAdvertisementRepository.instance.reload();

      await Get.dialog<void>(
        AlertDialog(
          title: Text(AppStrings.savedSuccessfully),
          content: Text(isEditing ? AppStrings.homeAdvertisementUpdated : AppStrings.homeAdvertisementCreated),
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
      _showMessage(AppStrings.saveHomeAdvertisementFailed, success: false);
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
    titleEnController.dispose();
    descriptionController.dispose();
    descriptionEnController.dispose();
    super.onClose();
  }
}

class AdminHomeAdvertisementFormBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map<String, dynamic>?;
    Get.put(AdminHomeAdvertisementFormController(args: args));
  }
}
