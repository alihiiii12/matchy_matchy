import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/network/api_client.dart';
import 'package:matchy_matchy/core/network/api_error.dart';

class StatisticsController extends GetxController {
  final loading = true.obs;
  final error = RxnString();
  final totalOrders = 0.obs;
  final totalSpent = 0.0.obs;

  int get favoritesCount => FavoritesController.instance.favoriteIds.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final res = await ApiClient.instance.getJson('/profile/statistics');
      final data = res.data!['data'] as Map<String, dynamic>;
      totalOrders.value = (data['total_orders'] as num?)?.toInt() ?? 0;
      totalSpent.value = (data['total_spent'] as num?)?.toDouble() ?? 0;
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل الإحصائيات');
    } finally {
      loading.value = false;
    }
  }
}

class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StatisticsController());
  }
}
