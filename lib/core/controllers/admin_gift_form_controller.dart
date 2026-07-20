import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/app_snackbar.dart';

class AdminGiftFormController extends GetxController {
  AdminGiftFormController({Map<String, dynamic>? gift})
      : editingGift = gift,
        isEditing = gift != null;

  final Map<String, dynamic>? editingGift;
  final bool isEditing;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final pointsCostController = TextEditingController();
  final percentController = TextEditingController();

  final submitting = false.obs;
  final loadingProducts = false.obs;
  final rewardType = 'discount_percent'.obs;
  final isActive = true.obs;
  final products = <Product>[].obs;
  final selectedProductId = RxnString();

  static const rewardTypes = [
    'discount_percent',
    'free_delivery',
    'free_product',
    'custom',
  ];

  @override
  void onInit() {
    super.onInit();
    if (isEditing) {
      titleController.text = editingGift!['title'] as String? ?? '';
      descriptionController.text = editingGift!['description'] as String? ?? '';
      pointsCostController.text = '${editingGift!['points_cost'] ?? ''}';
      rewardType.value = editingGift!['reward_type'] as String? ?? 'custom';
      isActive.value = editingGift!['is_active'] as bool? ?? true;
      final rewardValue = editingGift!['reward_value'] as Map<String, dynamic>?;
      percentController.text = '${rewardValue?['percent'] ?? ''}';
      selectedProductId.value = editingGift!['product_id'] as String? ?? rewardValue?['product_id'] as String?;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    loadingProducts.value = true;
    try {
      products.value = await CatalogRepository.instance.fetchProducts();
    } catch (_) {
      products.clear();
    } finally {
      loadingProducts.value = false;
    }
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final type = rewardType.value;
    final payload = <String, dynamic>{
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      'points_cost': int.parse(pointsCostController.text.trim()),
      'reward_type': type,
      'is_active': isActive.value,
    };

    if (type == 'discount_percent') {
      final percent = int.tryParse(percentController.text.trim());
      if (percent == null || percent < 1 || percent > 100) {
        _showMessage(AppStrings.giftPercentInvalid, success: false);
        return;
      }
      payload['reward_value'] = {'percent': percent};
      if (payload['title'] == '') {
        payload['title'] = 'خصم $percent%';
      }
    } else if (type == 'free_product') {
      final productId = selectedProductId.value;
      if (productId == null || productId.isEmpty) {
        _showMessage(AppStrings.giftProductRequired, success: false);
        return;
      }
      payload['product_id'] = productId;
      payload['reward_value'] = {'product_id': productId};
    }

    submitting.value = true;
    try {
      if (isEditing) {
        await ApiClient.instance.patchJson('/admin/gifts/${editingGift!['id']}', data: payload);
      } else {
        await ApiClient.instance.postJson('/admin/gifts', data: payload);
      }
      ApiClient.instance.invalidateGetCache('/gifts');
      _showMessage(isEditing ? AppStrings.giftRewardUpdated : AppStrings.giftRewardCreated, success: true);
      Get.back(result: true);
    } on DioException catch (e) {
      _showMessage(apiFriendlyError(e), success: false);
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
    descriptionController.dispose();
    pointsCostController.dispose();
    percentController.dispose();
    super.onClose();
  }
}

class AdminGiftFormBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments;
    Get.put(AdminGiftFormController(gift: args is Map<String, dynamic> ? args : null));
  }
}
