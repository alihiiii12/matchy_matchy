import 'dart:async';

import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/product.dart';

/// منتجات «الأكثر طلباً» فوق قسم جميع المنتجات.
class FeaturedProductsController extends GetxController {
  static FeaturedProductsController get instance => Get.find<FeaturedProductsController>();

  static const _defaultLimit = 8;

  final products = <Product>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    if (Get.isRegistered<AppSearchController>()) {
      ever(Get.find<AppSearchController>().catalogVersion, (_) => unawaited(load()));
    }
  }

  @override
  void onReady() {
    super.onReady();
    // إعادة التحميل بعد جاهزية الكتالوج من السبلاش
    unawaited(Future<void>.delayed(const Duration(milliseconds: 400), load));
  }

  Future<void> load({int limit = _defaultLimit}) async {
    final catalog = CategoryCatalog.products;
    if (catalog.isEmpty) {
      products.clear();
      return;
    }

    final marked = catalog.where((p) => p.isFeatured).toList();
    final pool = marked.isNotEmpty ? marked : catalog;
    products.assignAll(pool.take(limit));
  }
}
