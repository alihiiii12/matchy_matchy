import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class AdminProductSubmissionsController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final submissions = <Map<String, dynamic>>[].obs;
  final actionLoadingIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/product-submissions', query: {'status': 'pending'});
      submissions.assignAll((res.data!['data'] as List<dynamic>).cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      error.value = apiFriendlyError(e);
    } catch (_) {
      error.value = 'تعذر تحميل الطلبات';
    } finally {
      loading.value = false;
    }
  }

  bool isActionLoading(int id) => actionLoadingIds.contains(id);

  Future<void> approve(Map<String, dynamic> submission) async {
    final action = submission['action'] as String?;
    if (action == 'delete') {
      return _approveWithoutPoints(submission);
    }

    final pointsController = TextEditingController(
      text: '${(submission['current_product'] as Map<String, dynamic>?)?['points'] ?? 0}',
    );

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.productPointsOnApprove),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.productPointsOnApproveHint),
            const SizedBox(height: 12),
            TextField(
              controller: pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppStrings.productPointsLabel,
                hintText: '0',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.approveProduct)),
        ],
      ),
    );

    if (confirmed != true) {
      pointsController.dispose();
      return;
    }

    final points = int.tryParse(pointsController.text.trim()) ?? 0;
    pointsController.dispose();
    await _approveWithoutPoints(submission, points: points);
  }

  Future<void> _approveWithoutPoints(Map<String, dynamic> submission, {int? points}) async {
    final id = submission['id'] as int;
    actionLoadingIds.add(id);
    actionLoadingIds.refresh();
    try {
      await ApiClient.instance.postJson(
        '/admin/product-submissions/$id/approve',
        data: points != null ? {'points': points} : null,
      );
      Get.snackbar(AppStrings.appName, AppStrings.productApproved);
      await CatalogRepository.instance.reload();
      await load();
    } on DioException catch (e) {
      Get.snackbar(AppStrings.appName, apiFriendlyError(e));
    } catch (_) {
      Get.snackbar(AppStrings.appName, 'تعذر قبول الطلب');
    } finally {
      actionLoadingIds.remove(id);
      actionLoadingIds.refresh();
    }
  }

  Future<void> reject(Map<String, dynamic> submission) async {
    final id = submission['id'] as int;
    final reasonController = TextEditingController();

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(AppStrings.rejectProduct),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: AppStrings.rejectProductReason),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text(AppStrings.cancel)),
          TextButton(onPressed: () => Get.back(result: true), child: Text(AppStrings.rejectProduct)),
        ],
      ),
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }

    actionLoadingIds.add(id);
    actionLoadingIds.refresh();
    try {
      await ApiClient.instance.postJson(
        '/admin/product-submissions/$id/reject',
        data: {'reason': reasonController.text.trim()},
      );
      Get.snackbar(AppStrings.appName, AppStrings.productRejected);
      await load();
    } on DioException catch (e) {
      Get.snackbar(AppStrings.appName, apiFriendlyError(e));
    } catch (_) {
      Get.snackbar(AppStrings.appName, 'تعذر رفض الطلب');
    } finally {
      reasonController.dispose();
      actionLoadingIds.remove(id);
      actionLoadingIds.refresh();
    }
  }

  String approveButtonLabel(String? action) {
    if (action == 'delete') return AppStrings.approveProductDelete;
    return AppStrings.approveProduct;
  }

  String actionLabel(String? action) {
    switch (action) {
      case 'create':
        return AppStrings.productActionCreate;
      case 'update':
        return AppStrings.productActionUpdate;
      case 'delete':
        return AppStrings.productActionDelete;
      default:
        return action ?? '—';
    }
  }

  String formatPrice(dynamic price) {
    if (price == null) return '—';
    return CurrencyFormatter.format((price as num).toDouble());
  }
}

class AdminProductSubmissionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminProductSubmissionsController());
  }
}
