import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/services/admin_credit_points_service.dart';
import 'package:matchy_matchy/core/services/admin_users_pdf_exporter.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AdminUsersController extends GetxController {
  final loading = true.obs;
  final exporting = false.obs;
  final users = <Map<String, dynamic>>[].obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/users');
      final list = res.data!['data'] as List<dynamic>;
      users.value = list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل الحسابات');
    } finally {
      loading.value = false;
    }
  }

  Future<void> creditPoints(Map<String, dynamic> user) async {
    final ok = await AdminCreditPointsService.creditUser(user);
    if (ok) await load();
  }

  Future<void> exportPdf() async {
    if (users.isEmpty || exporting.value) return;

    exporting.value = true;
    try {
      await AdminUsersPdfExporter.export(users.toList());
    } catch (_) {
      Get.snackbar(AppStrings.appName, AppStrings.exportPdfFailed, backgroundColor: AppColors.error, colorText: Colors.white);
    } finally {
      exporting.value = false;
    }
  }
}

class AdminUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminUsersController());
  }
}
