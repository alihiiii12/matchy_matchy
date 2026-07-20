import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException, MultipartFile;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/multipart_image.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminEditSellerController extends GetxController {
  AdminEditSellerController({required this.seller});

  final Map<String, dynamic> seller;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final brandNameController = TextEditingController();
  final birthRegionController = TextEditingController();
  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();

  final submitting = false.obs;
  final birthDate = Rxn<DateTime>();
  final idFront = Rxn<File>();
  final idBack = Rxn<File>();
  final idFrontName = RxnString();
  final idBackName = RxnString();
  final idFrontBytes = Rxn<Uint8List>();
  final idBackBytes = Rxn<Uint8List>();

  int get sellerId => seller['id'] as int;

  @override
  void onInit() {
    super.onInit();
    final profile = seller['seller_profile'] as Map<String, dynamic>? ?? {};

    nameController.text = seller['name'] as String? ?? '';
    brandNameController.text = profile['brand_name'] as String? ?? '';
    birthRegionController.text = profile['birth_region'] as String? ?? '';
    fatherNameController.text = profile['father_name'] as String? ?? '';
    motherNameController.text = profile['mother_name'] as String? ?? '';
    nationalIdController.text = profile['national_id'] as String? ?? '';
    phoneController.text = seller['phone'] as String? ?? '';

    final birthDateRaw = profile['birth_date'] as String?;
    if (birthDateRaw != null && birthDateRaw.isNotEmpty) {
      birthDate.value = DateTime.tryParse(birthDateRaw);
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate.value ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      birthDate.value = picked;
    }
  }

  Future<void> pickIdPhoto({required bool front}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'heic'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final path = picked.path;
    final bytes = picked.bytes;
    File? file;

    if (path != null) {
      file = File(path);
    } else if (bytes != null) {
      final name = MultipartImage.resolveFilename(pickedName: picked.name, fallback: 'id.jpg');
      final tempFile = File('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
      await tempFile.writeAsBytes(bytes, flush: true);
      file = tempFile;
    } else {
      return;
    }

    if (front) {
      idFront.value = file;
      idFrontName.value = picked.name;
      idFrontBytes.value = bytes;
    } else {
      idBack.value = file;
      idBackName.value = picked.name;
      idBackBytes.value = bytes;
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (birthDate.value == null) {
      _showMessage('يرجى اختيار تاريخ التولد', success: false);
      return;
    }

    submitting.value = true;
    try {
      final birthDateValue = DateFormat('yyyy-MM-dd').format(birthDate.value!);
      final fields = <String, dynamic>{
        'name': nameController.text.trim(),
        'brand_name': brandNameController.text.trim(),
        'birth_region': birthRegionController.text.trim(),
        'birth_date': birthDateValue,
        'father_name': fatherNameController.text.trim(),
        'mother_name': motherNameController.text.trim(),
        'national_id': nationalIdController.text.trim(),
        'phone': phoneController.text.trim(),
      };

      Map<String, MultipartFile>? files;
      if (idFront.value != null) {
        files ??= {};
        files['id_front'] = await MultipartImage.fromPickedFile(
          file: idFront.value!,
          filename: idFrontName.value,
          bytes: idFrontBytes.value,
        );
      }
      if (idBack.value != null) {
        files ??= {};
        files['id_back'] = await MultipartImage.fromPickedFile(
          file: idBack.value!,
          filename: idBackName.value,
          bytes: idBackBytes.value,
        );
      }

      await ApiClient.instance.patchMultipart(
        '/admin/sellers/$sellerId',
        fields: fields,
        files: files,
      );

      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage(AppStrings.editSellerFailed, success: false);
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
    brandNameController.dispose();
    birthRegionController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    nationalIdController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}

class AdminEditSellerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminEditSellerController(seller: Get.arguments as Map<String, dynamic>));
  }
}
