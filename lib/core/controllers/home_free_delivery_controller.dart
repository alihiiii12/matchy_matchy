import 'dart:async';

import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';

class HomeFreeDeliveryController extends GetxController {
  final products = <Product>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    if (Get.isRegistered<AppSearchController>()) {
      ever(Get.find<AppSearchController>().catalogVersion, (_) => unawaited(load()));
    }
  }

  Future<void> load() async {
    loading.value = true;
    try {
      if (CatalogRepository.instance.isFromApi) {
        products.assignAll(await CatalogRepository.instance.fetchFreeDeliveryProducts());
      } else {
        products.assignAll(CategoryCatalog.freeDeliveryProducts());
      }
    } catch (_) {
      products.assignAll(CategoryCatalog.freeDeliveryProducts());
    } finally {
      loading.value = false;
    }
  }
}
