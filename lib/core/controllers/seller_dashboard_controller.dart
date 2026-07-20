import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';

class SellerDashboardController extends GetxController {
  final loading = true.obs;
  final error = RxnString();

  final publishedProducts = 0.obs;
  final pendingProducts = 0.obs;
  final totalUnitsSold = 0.obs;
  final totalRevenue = 0.0.obs;
  final monthUnitsSold = 0.obs;
  final monthRevenue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/seller/sales-stats');
      final data = res.data!['data'] as Map<String, dynamic>;

      publishedProducts.value = data['published_products'] as int? ?? 0;
      pendingProducts.value = data['pending_products'] as int? ?? 0;

      final total = data['total'] as Map<String, dynamic>? ?? {};
      totalUnitsSold.value = total['units_sold'] as int? ?? 0;
      totalRevenue.value = (total['revenue'] as num?)?.toDouble() ?? 0;

      final month = data['month'] as Map<String, dynamic>? ?? {};
      monthUnitsSold.value = month['units_sold'] as int? ?? 0;
      monthRevenue.value = (month['revenue'] as num?)?.toDouble() ?? 0;
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل إحصائيات البيع');
    } catch (_) {
      error.value = 'تعذر تحميل إحصائيات البيع';
    } finally {
      loading.value = false;
    }
  }
}
