import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/otp_verification_args.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/network/multipart_image.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';
import 'package:matchy_matchy/core/utils/auth_validation.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class EditProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  final submitting = false.obs;
  final avatarFile = Rxn<File>();
  final avatarFileName = RxnString();
  final avatarBytes = Rxn<Uint8List>();
  final emailError = RxnString();
  final phoneError = RxnString();
  final nameError = RxnString();

  String? _originalEmail;
  String? _originalPhone;

  String? get existingAvatarUrl => AuthService.instance.user?.avatarUrl;

  bool get isStaff {
    final role = AuthService.instance.user?.role;
    return role == 'seller' || role == 'driver' || role == 'admin';
  }

  bool get isAdmin => AuthService.instance.user?.isAdmin == true;

  /// البائع والسائق فقط — المدير يعدّل بريده ورقمه مباشرة.
  bool get isContactLocked {
    final role = AuthService.instance.user?.role;
    return role == 'seller' || role == 'driver';
  }

  String get lockedPhoneDisplay {
    final phone = phoneController.text.trim();
    return phone.isEmpty ? AppStrings.phoneNotSet : phone;
  }

  @override
  void onInit() {
    super.onInit();
    final user = AuthService.instance.user;
    nameController = TextEditingController(text: user?.name ?? '');
    final phone = user?.phone?.trim() ?? '';
    final lockedStaff = user != null && (user.isSeller || user.isDriver);
    phoneController = TextEditingController(
      text: phone.isNotEmpty ? phone : (lockedStaff ? AppStrings.phoneNotSet : ''),
    );
    emailController = TextEditingController(text: user?.email ?? '');
    _originalEmail = user?.email ?? '';
    _originalPhone = user?.phone ?? '';
  }

  Future<void> pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final path = picked.path;
    var bytes = picked.bytes;

    if (path != null) {
      final file = File(path);
      avatarFile.value = file;
      bytes ??= await file.readAsBytes();
    } else if (bytes != null) {
      final name = MultipartImage.resolveFilename(pickedName: picked.name, fallback: 'avatar.jpg');
      final tempFile = File('${Directory.systemTemp.path}${Platform.pathSeparator}$name');
      await tempFile.writeAsBytes(bytes, flush: true);
      avatarFile.value = tempFile;
    } else {
      return;
    }

    avatarFileName.value = picked.name;
    avatarBytes.value = bytes;
  }

  bool _validateFields() {
    nameError.value = AuthValidation.name(nameController.text);
    if (isContactLocked) {
      phoneError.value = null;
      emailError.value = null;
      return nameError.value == null;
    }

    phoneError.value = AuthValidation.phone(phoneController.text);
    emailError.value = AuthValidation.email(emailController.text);

    return nameError.value == null && phoneError.value == null && emailError.value == null;
  }

  bool get _contactChanged {
    if (isContactLocked) return false;
    final email = emailController.text.trim().toLowerCase();
    final phone = phoneController.text.trim();
    return email != (_originalEmail ?? '').trim().toLowerCase() || phone != (_originalPhone ?? '').trim();
  }

  Future<void> submit() async {
    if (!_validateFields()) return;

    submitting.value = true;
    try {
      final avatar = avatarFile.value;
      Uint8List? bytes = avatarBytes.value;
      if (avatar != null && (bytes == null || bytes.isEmpty)) {
        bytes = await avatar.readAsBytes();
        avatarBytes.value = bytes;
      }

      final result = await AuthService.instance.updateProfile(
        name: nameController.text.trim(),
        phone: isContactLocked ? (_originalPhone ?? '') : phoneController.text.trim(),
        email: isContactLocked ? (_originalEmail ?? '') : emailController.text.trim(),
        avatar: avatar,
        avatarFileName: avatarFileName.value,
        avatarBytes: bytes,
      );

      if (result.requiresOtp) {
        submitting.value = false;
        final otpMessage = result.changesEmail && result.changesPhone
            ? (result.message ?? AppStrings.profileUpdateBothOtpSent)
            : (result.message ?? AppStrings.profileUpdateOtpSent);
        _showMessage(otpMessage, success: true);
        final verified = await Get.toNamed(
          AppRoutes.verifyOtp,
          arguments: OtpVerificationArgs(
            email: result.email ?? emailController.text.trim(),
            flow: OtpFlow.profileUpdate,
          ),
        );

        if (verified == true) {
          avatarFile.value = null;
          avatarFileName.value = null;
          avatarBytes.value = null;
          await AuthService.instance.refreshProfile();
          await _showSuccessDialog();
          Get.back(result: true);
        }
        return;
      }

      if (_contactChanged) {
        _originalEmail = emailController.text.trim();
        _originalPhone = phoneController.text.trim();
      }

      avatarFile.value = null;
      avatarFileName.value = null;
      avatarBytes.value = null;

      await AuthService.instance.refreshProfile();

      if (result.avatarUploadFailed) {
        _showMessage(
          result.message ?? 'تم حفظ الاسم والبريد والهاتف لكن تعذر رفع الصورة',
          success: false,
        );
        Get.back(result: true);
        return;
      }

      await _showSuccessDialog(message: result.message);
      Get.back(result: true);
    } on DioException catch (e) {
      _handleError(e);
    } catch (_) {
      _showMessage(AppStrings.saveProfileFailed, success: false);
    } finally {
      submitting.value = false;
    }
  }

  Future<void> _showSuccessDialog({String? message}) {
    return Get.dialog<void>(
      AlertDialog(
        title: Text(AppStrings.savedSuccessfully),
        content: Text(message ?? AppStrings.profileUpdated),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _handleError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        emailError.value = _firstError(errors['email']);
        phoneError.value = _firstError(errors['phone']);
        nameError.value = _firstError(errors['name']);
      }
    }

    if (emailError.value == null && phoneError.value == null && nameError.value == null) {
      _showMessage(apiFriendlyError(error, fallback: AppStrings.saveProfileFailed), success: false);
    }
  }

  String? _firstError(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String && value.isNotEmpty) return value;
    return null;
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
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
  }
}

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(EditProfileController());
  }
}
