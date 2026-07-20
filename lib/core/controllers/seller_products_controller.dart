import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class SellerProductsController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final brandName = RxnString();
  final items = <Map<String, dynamic>>[].obs;
  final actionLoadingIds = <String>{}.obs;

  List<Map<String, dynamic>> get publishedItems =>
      items.where((item) => item['kind'] == 'product' && item['has_pending'] != true).toList();

  List<Map<String, dynamic>> get pendingItems => items.where((item) {
        if (item['kind'] == 'submission') return true;
        return item['kind'] == 'product' && item['has_pending'] == true;
      }).toList();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      await CatalogRepository.instance.load();
      final res = await ApiClient.instance.getJson('/seller/products');
      final data = res.data!['data'] as Map<String, dynamic>;
      brandName.value = data['brand_name'] as String?;
      items.assignAll((data['items'] as List<dynamic>).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      error.value = apiFriendlyError(e);
    } catch (_) {
      error.value = 'تعذر تحميل المنتجات';
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(String id) => actionLoadingIds.contains(id);

  Future<void> openCreateForm() async {
    final created = await Get.toNamed(AppRoutes.sellerProductForm);
    if (created == true) await load();
  }

  Future<void> openEditForm(Map<String, dynamic> product) async {
    if (product['has_pending'] == true) {
      Get.snackbar(AppStrings.appName, 'يوجد طلب قيد المراجعة لهذا المنتج');
      return;
    }
    final updated = await Get.toNamed(AppRoutes.sellerProductForm, arguments: product);
    if (updated == true) await load();
  }

  Future<void> requestDelete(Map<String, dynamic> product) async {
    if (product['has_pending'] == true) {
      Get.snackbar(AppStrings.appName, 'يوجد طلب قيد المراجعة لهذا المنتج');
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.deleteProduct),
        content: Text(AppStrings.deleteProductConfirm),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.deleteProduct, style: TextStyle(color: Get.theme.colorScheme.error))),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = product['id'] as String;
    actionLoadingIds.add(id);
    actionLoadingIds.refresh();
    try {
      await ApiClient.instance.postJson('/seller/products/$id/delete-request');
      Get.snackbar(AppStrings.appName, AppStrings.productDeleteSubmitted);
      await load();
    } on DioException catch (e) {
      Get.snackbar(AppStrings.appName, apiFriendlyError(e));
    } catch (_) {
      Get.snackbar(AppStrings.appName, 'تعذر إرسال طلب الحذف');
    } finally {
      actionLoadingIds.remove(id);
      actionLoadingIds.refresh();
    }
  }
}

class SellerProductsBinding extends Bindings {
  SellerProductsBinding({this.tag});

  final String? tag;

  @override
  void dependencies() {
    if (tag != null) {
      if (!Get.isRegistered<SellerProductsController>(tag: tag)) {
        Get.put(SellerProductsController(), tag: tag);
      }
      return;
    }
    Get.put(SellerProductsController());
  }
}
