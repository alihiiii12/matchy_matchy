import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';
import 'package:matchy_matchy/core/services/auth_service.dart';

class OrderHistoryController extends GetxController {
  final orders = <OrderSummary>[].obs;
  final loading = true.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (!AuthService.instance.isLoggedIn) {
      orders.clear();
      error.value = null;
      loading.value = false;
      return;
    }

    loading.value = true;
    error.value = null;
    try {
      final fetched = await OrderRepository.instance.fetchOrders();
      orders.value = fetched;
    } on DioException catch (e) {
      orders.clear();
      error.value = apiFriendlyError(e, fallback: 'تعذر تحميل سجل الطلبات');
    } catch (_) {
      orders.clear();
      error.value = 'تعذر تحميل سجل الطلبات';
    } finally {
      loading.value = false;
    }
  }
}

class OrderHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OrderHistoryController());
  }
}
