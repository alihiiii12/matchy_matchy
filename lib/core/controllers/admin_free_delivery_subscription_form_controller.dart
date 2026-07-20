import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminFreeDeliverySubscriptionFormController extends GetxController {
  AdminFreeDeliverySubscriptionFormController({Map<String, dynamic>? subscription})
      : editingSubscription = subscription,
        isEditing = subscription != null;

  final Map<String, dynamic>? editingSubscription;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();

  final submitting = false.obs;
  final loadingSellers = false.obs;
  final sellers = <Map<String, dynamic>>[].obs;
  final selectedSellerId = RxnInt();
  final startsAt = Rxn<DateTime>();
  final expiresAt = Rxn<DateTime>();

  static final _dateFormat = DateFormat('yyyy-MM-dd', 'en');

  String formatDate(DateTime? date, {required String placeholder}) {
    if (date == null) return placeholder;
    return _dateFormat.format(date);
  }

  String get startsAtLabel => formatDate(startsAt.value, placeholder: AppStrings.pickStartDate);
  String get expiresAtLabel => formatDate(expiresAt.value, placeholder: AppStrings.pickEndDate);

  List<Map<String, dynamic>> get sellersWithBrand {
    return sellers.where((seller) {
      final profile = seller['seller_profile'] as Map<String, dynamic>?;
      final brand = profile?['brand_name'] as String?;
      return brand != null && brand.trim().isNotEmpty;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      selectedSellerId.value = editingSubscription!['seller_user_id'] as int?;
      amountController.text = '${editingSubscription!['amount_paid'] ?? ''}';

      final startRaw = editingSubscription!['starts_at'] as String?;
      if (startRaw != null && startRaw.isNotEmpty) {
        startsAt.value = DateTime.tryParse(startRaw)?.toLocal();
      }

      final endRaw = editingSubscription!['expires_at'] as String?;
      if (endRaw != null && endRaw.isNotEmpty) {
        expiresAt.value = DateTime.tryParse(endRaw)?.toLocal();
      }
    }
    loadSellers();
  }

  Future<void> loadSellers() async {
    loadingSellers.value = true;
    try {
      final res = await ApiClient.instance.getJson('/admin/sellers');
      final list = res.data!['data'] as List<dynamic>;
      sellers.assignAll(list.cast<Map<String, dynamic>>());
      _syncSelectedSeller();
    } catch (_) {
      sellers.clear();
      selectedSellerId.value = null;
    } finally {
      loadingSellers.value = false;
    }
  }

  void _syncSelectedSeller() {
    final selected = selectedSellerId.value;
    if (selected == null) return;

    final exists = sellersWithBrand.any((seller) => seller['id'] == selected);
    if (!exists) {
      selectedSellerId.value = null;
    }
  }

  String sellerLabel(Map<String, dynamic> seller) {
    final profile = seller['seller_profile'] as Map<String, dynamic>?;
    final brand = profile?['brand_name'] as String? ?? '—';
    final name = seller['name'] as String? ?? '';
    return name.isEmpty ? brand : '$brand — $name';
  }

  Future<void> pickStartsAt(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startsAt.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      startsAt.value = DateTime(picked.year, picked.month, picked.day);
      if (expiresAt.value != null && expiresAt.value!.isBefore(startsAt.value!)) {
        expiresAt.value = null;
      }
    }
  }

  Future<void> pickExpiresAt(BuildContext context) async {
    final now = DateTime.now();
    final minDate = startsAt.value ?? DateTime(now.year - 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt.value ?? (startsAt.value ?? now.add(const Duration(days: 30))),
      firstDate: minDate,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      expiresAt.value = DateTime(picked.year, picked.month, picked.day);
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedSellerId.value == null) {
      _showMessage(AppStrings.freeDeliverySubscriptionBrandRequired, success: false);
      return;
    }

    if (startsAt.value == null) {
      _showMessage(AppStrings.freeDeliverySubscriptionStartRequired, success: false);
      return;
    }

    if (expiresAt.value == null) {
      _showMessage(AppStrings.freeDeliverySubscriptionEndRequired, success: false);
      return;
    }

    if (expiresAt.value!.isBefore(startsAt.value!)) {
      _showMessage(AppStrings.freeDeliverySubscriptionEndBeforeStart, success: false);
      return;
    }

    submitting.value = true;
    try {
      final payload = <String, dynamic>{
        'seller_user_id': selectedSellerId.value,
        'starts_at': _dateFormat.format(startsAt.value!),
        'expires_at': _dateFormat.format(expiresAt.value!),
        'amount_paid': double.parse(amountController.text.trim()),
      };

      if (isEditing) {
        await ApiClient.instance.patchJson(
          '/admin/free-delivery-subscriptions/${editingSubscription!['id']}',
          data: payload,
        );
      } else {
        await ApiClient.instance.postJson('/admin/free-delivery-subscriptions', data: payload);
      }

      await _showSuccessDialog();
      await CatalogRepository.instance.reload();
      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e, fallback: AppStrings.saveFreeDeliverySubscriptionFailed), success: false);
    } catch (_) {
      _showMessage(AppStrings.saveFreeDeliverySubscriptionFailed, success: false);
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

  Future<void> _showSuccessDialog() async {
    await Get.dialog<void>(
      AlertDialog(
        title: Text(AppStrings.savedSuccessfully),
        content: Text(isEditing ? AppStrings.freeDeliverySubscriptionUpdated : AppStrings.freeDeliverySubscriptionCreated),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text(AppStrings.done)),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }
}

class AdminFreeDeliverySubscriptionFormBinding extends Bindings {
  @override
  void dependencies() {
    final subscription = Get.arguments as Map<String, dynamic>?;
    Get.put(AdminFreeDeliverySubscriptionFormController(subscription: subscription));
  }
}
