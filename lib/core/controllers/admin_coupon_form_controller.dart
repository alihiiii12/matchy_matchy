import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminCouponFormController extends GetxController {
  AdminCouponFormController({Map<String, dynamic>? coupon})
      : editingCoupon = coupon,
        isEditing = coupon != null;

  final Map<String, dynamic>? editingCoupon;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final valueController = TextEditingController();
  final perUserLimitController = TextEditingController(text: '1');

  final submitting = false.obs;
  final expiresAt = Rxn<DateTime>();
  final couponType = 'percent'.obs;

  static final _dateFormat = DateFormat('yyyy-MM-dd', 'en');

  String get expiresAtLabel {
    final date = expiresAt.value;
    if (date == null) return AppStrings.pickExpiryDate;
    return _dateFormat.format(date);
  }

  String get valueFieldLabel =>
      couponType.value == 'fixed' ? 'قيمة الخصم (ل.س)' : AppStrings.couponValuePercent;

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      nameController.text = editingCoupon!['name'] as String? ?? '';
      valueController.text = '${editingCoupon!['value'] ?? ''}';
      perUserLimitController.text = '${editingCoupon!['per_user_limit'] ?? 1}';
      couponType.value = editingCoupon!['type'] as String? ?? 'percent';

      final raw = editingCoupon!['expires_at'] as String?;
      if (raw != null && raw.isNotEmpty) {
        expiresAt.value = DateTime.tryParse(raw)?.toLocal();
      }
    }
  }

  Future<void> pickExpiryDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt.value ?? now.add(const Duration(days: 30)),
      firstDate: isEditing ? DateTime(now.year - 1) : now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      expiresAt.value = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (expiresAt.value == null) {
      _showMessage(AppStrings.couponExpiryRequired, success: false);
      return;
    }

    if (!isEditing && expiresAt.value!.isBefore(DateTime.now())) {
      _showMessage(AppStrings.couponExpiryMustBeFuture, success: false);
      return;
    }

    submitting.value = true;
    try {
      final payload = <String, dynamic>{
        'name': nameController.text.trim(),
        'type': couponType.value,
        'value': int.parse(valueController.text.trim()),
        'per_user_limit': int.parse(perUserLimitController.text.trim()),
        'expires_at': expiresAt.value!.toUtc().toIso8601String(),
      };

      if (isEditing) {
        await ApiClient.instance.patchJson('/admin/coupons/${editingCoupon!['id']}', data: payload);
      } else {
        await ApiClient.instance.postJson('/admin/coupons', data: payload);
      }

      await Get.dialog<void>(
        AlertDialog(
          title: Text(AppStrings.savedSuccessfully),
          content: Text(isEditing ? AppStrings.couponUpdated : AppStrings.couponCreated),
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
      _showMessage(AppStrings.saveCouponFailed, success: false);
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
    valueController.dispose();
    perUserLimitController.dispose();
    super.onClose();
  }
}

class AdminCouponFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminCouponFormController(coupon: Get.arguments as Map<String, dynamic>?));
  }
}
