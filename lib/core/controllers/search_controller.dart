import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/repositories/catalog_repository.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class AppSearchController extends GetxController {
  final queryController = TextEditingController();
  final results = <Product>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final categoryId = RxnString();
  final subCategoryId = RxnString();
  final brandFilter = RxnString();
  final viewAllMode = false.obs;
  final catalogVersion = 0.obs;

  Timer? _debounce;

  bool get hasActiveSearch =>
      viewAllMode.value ||
      searchQuery.value.trim().isNotEmpty ||
      (brandFilter.value != null && brandFilter.value!.isNotEmpty) ||
      (categoryId.value != null && categoryId.value!.isNotEmpty) ||
      (subCategoryId.value != null && subCategoryId.value!.isNotEmpty);

  String? get selectedCategoryName =>
      categoryId.value == null ? null : CategoryCatalog.categoryById(categoryId.value!)?.name;

  String? get selectedSubCategoryName =>
      subCategoryId.value == null ? null : CategoryCatalog.subCategoryById(subCategoryId.value!)?.name;

  @override
  void onInit() {
    super.onInit();
    queryController.addListener(_onQueryInputChanged);
  }

  @override
  void onClose() {
    _debounce?.cancel();
    queryController.removeListener(_onQueryInputChanged);
    queryController.dispose();
    super.onClose();
  }

  void _onQueryInputChanged() {
    searchQuery.value = queryController.text;
    if (searchQuery.value.trim().isNotEmpty) {
      viewAllMode.value = false;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) unawaited(runSearch());
    });
  }

  Future<void> refreshCatalog() async {
    await CatalogRepository.instance.reload();
  }

  Future<List<Product>> _fetchProductsWithFallback({
    String? query,
    String? categoryId,
    String? subCategoryId,
    String? brand,
  }) async {
    if (CatalogRepository.instance.isFromApi) {
      try {
        final fetched = await CatalogRepository.instance.fetchProducts(
          query: query,
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          brand: brand,
        );
        if (fetched.isNotEmpty) return fetched;
      } catch (_) {}
    }

    return CatalogRepository.instance.filterProductsLocally(
      query: query,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      brand: brand,
    );
  }

  Future<void> runSearch() async {
    if (!hasActiveSearch) {
      results.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    final query = searchQuery.value.trim();

    try {
      results.assignAll(
        await _fetchProductsWithFallback(
          query: query.isEmpty ? null : query,
          categoryId: categoryId.value,
          subCategoryId: subCategoryId.value,
          brand: brandFilter.value,
        ),
      );
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void setFilters({String? categoryId, String? subCategoryId}) {
    viewAllMode.value = false;
    brandFilter.value = null;
    this.categoryId.value = categoryId;
    this.subCategoryId.value = subCategoryId;
    unawaited(runSearch());
  }

  void clearFilters() {
    viewAllMode.value = false;
    categoryId.value = null;
    subCategoryId.value = null;
    brandFilter.value = null;
    unawaited(runSearch());
  }

  void setQuery(String query) {
    viewAllMode.value = false;
    brandFilter.value = null;
    queryController.text = query;
    searchQuery.value = query;
    unawaited(runSearch());
  }

  void setBrandFilter(String brand) {
    viewAllMode.value = false;
    queryController.clear();
    searchQuery.value = '';
    categoryId.value = null;
    subCategoryId.value = null;
    brandFilter.value = brand.trim();
    unawaited(runSearch());
  }

  Future<void> openFilter() async {
    await refreshCatalog();
    await Get.toNamed(AppRoutes.searchFilter);
    if (!isClosed) {
      await runSearch();
    }
  }

  Future<void> showAllProducts() async {
    _debounce?.cancel();
    viewAllMode.value = true;
    queryController.clear();
    searchQuery.value = '';
    categoryId.value = null;
    subCategoryId.value = null;
    brandFilter.value = null;
    isLoading.value = true;

    try {
      var list = await _fetchProductsWithFallback();
      if (list.isEmpty && CatalogRepository.instance.isFromApi) {
        await CatalogRepository.instance.reload();
        list = await _fetchProductsWithFallback();
      }
      results.assignAll(list);
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void openCategoryProducts(Object category) => Get.toNamed(AppRoutes.categoryProducts, arguments: category);

  /// توافق مع الاستدعاءات القديمة.
  void openSubCategories(Object category) => openCategoryProducts(category);

  void submitSearch(String query) {
    setQuery(query);
  }
}

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AppSearchController>()) {
      Get.put(AppSearchController(), permanent: true);
    }
  }
}
