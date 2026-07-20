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

class AdminCreateDriverController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final vehicleTypeController = TextEditingController();
  final plateNumberController = TextEditingController();
  final birthRegionController = TextEditingController();
  final fatherNameController = TextEditingController();
  final motherNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();
  final subscriptionMonthsController = TextEditingController(text: '12');
  final subscriptionAmountPaidController = TextEditingController();
  final commissionPercentController = TextEditingController(text: '10');
  final payModel = 'subscription'.obs;

  final submitting = false.obs;
  final birthDate = Rxn<DateTime>();
  final idFront = Rxn<File>();
  final idBack = Rxn<File>();
  final idFrontName = RxnString();
  final idBackName = RxnString();
  final idFrontBytes = Rxn<Uint8List>();
  final idBackBytes = Rxn<Uint8List>();
  final governorates = <Map<String, dynamic>>[].obs;
  final selectedGovernorateId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadGovernorates();
  }

  Future<void> _loadGovernorates() async {
    try {
      final res = await ApiClient.instance.getJson('/governorates');
      final list = res.data!['data'] as List<dynamic>;
      governorates.assignAll(list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate.value ?? DateTime(1990, 1, 1),
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

    if (idFront.value == null || idBack.value == null) {
      _showMessage('يرجى إرفاق صورتي الهوية', success: false);
      return;
    }

    submitting.value = true;
    try {
      final fields = <String, dynamic>{
        'name': nameController.text.trim(),
        'vehicle_type': vehicleTypeController.text.trim(),
        'plate_number': plateNumberController.text.trim(),
        'birth_region': birthRegionController.text.trim(),
        'birth_date': DateFormat('yyyy-MM-dd').format(birthDate.value!),
        'father_name': fatherNameController.text.trim(),
        'mother_name': motherNameController.text.trim(),
        'national_id': nationalIdController.text.trim(),
        'phone': phoneController.text.trim(),
        'pay_model': payModel.value,
      };

      if (payModel.value == 'percentage') {
        fields['commission_percent'] = commissionPercentController.text.trim();
        fields['subscription_months'] = '0';
        fields['subscription_amount_paid'] = '0';
      } else {
        fields['subscription_months'] = int.parse(subscriptionMonthsController.text.trim()).toString();
        fields['subscription_amount_paid'] = double.parse(subscriptionAmountPaidController.text.trim()).toString();
      }

      if (selectedGovernorateId.value != null) {
        fields['governorate_id'] = selectedGovernorateId.value;
      }

      final res = await ApiClient.instance.postMultipart(
        '/admin/drivers',
        fields: fields,
        files: {
          'id_front': await MultipartImage.fromPickedFile(
            file: idFront.value!,
            filename: idFrontName.value,
            bytes: idFrontBytes.value,
          ),
          'id_back': await MultipartImage.fromPickedFile(
            file: idBack.value!,
            filename: idBackName.value,
            bytes: idBackBytes.value,
          ),
        },
      );

      final credentials = res.data!['credentials'] as Map<String, dynamic>;
      await _showCredentialsDialog(
        email: credentials['email'] as String,
        password: credentials['password'] as String,
      );

      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
    } catch (_) {
      _showMessage('تعذر إنشاء حساب السائق', success: false);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> _showCredentialsDialog({required String email, required String password}) async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(AppStrings.driverCredentialsTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.driverCredentialsHint, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _CredentialRow(
              label: AppStrings.email,
              value: email,
              onCopy: () => _copyText(email, AppStrings.email),
            ),
            const SizedBox(height: 12),
            _CredentialRow(
              label: AppStrings.password,
              value: password,
              onCopy: () => _copyText(password, AppStrings.password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _copyText('${AppStrings.email}: $email\n${AppStrings.password}: $password', AppStrings.driverCredentialsTitle),
            child: Text(AppStrings.copyAllCredentials),
          ),
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _copyText(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showMessage('${AppStrings.copiedToClipboard}: $label', success: true);
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
    vehicleTypeController.dispose();
    plateNumberController.dispose();
    birthRegionController.dispose();
    fatherNameController.dispose();
    motherNameController.dispose();
    nationalIdController.dispose();
    phoneController.dispose();
    subscriptionMonthsController.dispose();
    subscriptionAmountPaidController.dispose();
    super.onClose();
  }
}

class AdminCreateDriverBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCreateDriverController());
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({required this.label, required this.value, required this.onCopy});

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SelectableText('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined, size: 20),
          tooltip: label,
        ),
      ],
    );
  }
}
