import 'dart:async';

import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';

class SearchFilterController extends GetxController {
  final loading = true.obs;
  final categories = <ShopCategory>[].obs;
  final subCategories = <SubCategory>[].obs;
  final selectedCategoryId = RxnString();
  final selectedSubCategoryId = RxnString();

  bool get hasSelectedCategory =>
      selectedCategoryId.value != null && selectedCategoryId.value!.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    final search = Get.find<AppSearchController>();
    selectedCategoryId.value = search.categoryId.value;
    selectedSubCategoryId.value = search.subCategoryId.value;
    unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    loading.value = true;
    try {
      await CatalogRepository.instance.reload();
    } catch (_) {
      // Keep whatever catalog data is already available.
    }

    categories.assignAll(CategoryCatalog.categories);
    _refreshSubCategories();
    _syncSelections();
    loading.value = false;
  }

  void _refreshSubCategories() {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null || categoryId.isEmpty) {
      subCategories.clear();
      return;
    }

    for (final category in categories) {
      if (category.id == categoryId) {
        subCategories.assignAll(category.subCategories);
        return;
      }
    }

    subCategories.clear();
  }

  void _syncSelections() {
    final categoryId = selectedCategoryId.value;
    if (categoryId != null && !categories.any((category) => category.id == categoryId)) {
      selectedCategoryId.value = null;
      selectedSubCategoryId.value = null;
      return;
    }

    final subCategoryId = selectedSubCategoryId.value;
    if (subCategoryId != null && !subCategories.any((sub) => sub.id == subCategoryId)) {
      selectedSubCategoryId.value = null;
    }
  }

  void selectCategory(String? value) {
    selectedCategoryId.value = value;
    selectedSubCategoryId.value = null;
    _refreshSubCategories();
  }

  void selectSubCategory(String? value) {
    selectedSubCategoryId.value = value;
  }

  void clearAll() {
    selectedCategoryId.value = null;
    selectedSubCategoryId.value = null;
    subCategories.clear();
  }

  void applyFilter() {
    Get.find<AppSearchController>().setFilters(
      categoryId: selectedCategoryId.value,
      subCategoryId: selectedSubCategoryId.value,
    );
    Get.back(result: true);
  }
}

class SearchFilterBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SearchFilterController());
  }
}
