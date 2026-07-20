import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/network/api_error.dart';
import 'package:matchy_matchy/core/repositories/order_repository.dart';

class OrderTrackController extends GetxController {
  final order = Rxn<OrderSummary>();
  final loading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments as OrderSummary?;
    if (arg == null) return;

    order.value = arg;
    refreshOrder(arg.id);
  }

  Future<void> refreshOrder(int id) async {
    loading.value = true;
    error.value = null;
    try {
      order.value = await OrderRepository.instance.fetchOrderById(id);
    } on DioException catch (e) {
      error.value = apiFriendlyError(e, fallback: 'تعذر تحديث بيانات الطلب');
    } catch (_) {
      error.value = 'تعذر تحديث بيانات الطلب';
    } finally {
      loading.value = false;
    }
  }
}

class OrderTrackBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(OrderTrackController());
  }
}
