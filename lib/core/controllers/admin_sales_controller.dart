import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/services/admin_sales_pdf_exporter.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';

class AdminSalesController extends GetxController {
  final loading = true.obs;
  final exporting = false.obs;
  final sales = <Map<String, dynamic>>[].obs;
  final error = RxnString();
  final totalLines = 0.obs;
  final totalRevenue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/admin/sales');
      final list = res.data!['data'] as List<dynamic>;
      sales.value = list.cast<Map<String, dynamic>>();

      final meta = res.data!['meta'] as Map<String, dynamic>?;
      totalLines.value = meta?['total_lines'] as int? ?? sales.length;
      totalRevenue.value = (meta?['total_revenue'] as num?)?.toDouble() ?? 0;
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: AppStrings.loadSalesFailed);
    } finally {
      loading.value = false;
    }
  }

  Future<void> exportPdf() async {
    if (sales.isEmpty || exporting.value) return;

    exporting.value = true;
    try {
      await AdminSalesPdfExporter.export(
        sales: sales.toList(),
        totalLines: totalLines.value,
        totalRevenue: totalRevenue.value,
      );
    } catch (_) {
      Get.snackbar(
        AppStrings.appName,
        AppStrings.exportPdfFailed,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      exporting.value = false;
    }
  }
}

class AdminSalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AdminSalesController());
  }
}
