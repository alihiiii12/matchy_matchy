import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/network/api_client.dart';

class CatalogRepository {
  CatalogRepository._();
  static final instance = CatalogRepository._();

  bool _loaded = false;
  bool _fromApi = false;
  String? lastError;

  bool get isFromApi => _fromApi;

  Future<void> load() async {
    if (_loaded) return;
    await _fetchAndReplace();
  }

  Future<void> reload() async {
    _loaded = false;
    await _fetchAndReplace();
  }

  Future<void> _fetchAndReplace() async {
    List<ShopCategory>? categories;
    List<Product>? products;
    lastError = null;

    try {
      final categoriesRes = await ApiClient.instance.getJson('/categories', force: true);
      final categoriesJson = categoriesRes.data!['data'] as List<dynamic>;
      categories = categoriesJson
          .map((json) => _categoryFromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      lastError = e.toString();
    }

    try {
      final productsRes = await ApiClient.instance.getJson('/products', force: true);
      final productsJson = productsRes.data!['data'] as List<dynamic>;
      products = productsJson
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      lastError = e.toString();
    }

    // أي نجاح من الـ API يستبدل الكتالوج المحلي — لا نبقي منتجات زادك الوهمية.
    if (categories != null || products != null) {
      CategoryCatalog.replaceData(
        categories: categories ?? CategoryCatalog.categories,
        products: products ?? const [],
      );
      _fromApi = true;
      _notifyCatalogChanged();
    } else {
      _fromApi = false;
    }

    _loaded = true;
  }

  Future<List<Product>> fetchFreeDeliveryProducts({int limit = 12}) async {
    final response = await ApiClient.instance.getJson('/products', query: {'free_delivery': '1'});
    final productsJson = response.data!['data'] as List<dynamic>;
    return productsJson
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .take(limit)
        .toList();
  }

  Future<List<Product>> fetchFeaturedProducts({int limit = 8}) async {
    final response = await ApiClient.instance.getJson('/products', query: {'featured': '1'});
    final productsJson = response.data!['data'] as List<dynamic>;
    return productsJson
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .take(limit)
        .toList();
  }

  Future<List<Product>> fetchProducts({
    String? query,
    String? categoryId,
    String? subCategoryId,
    String? brand,
    String? role,
    String? size,
  }) async {
    final params = <String, dynamic>{};
    final q = query?.trim();
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (categoryId != null && categoryId.isNotEmpty) params['category_id'] = categoryId;
    if (subCategoryId != null && subCategoryId.isNotEmpty) params['sub_category_id'] = subCategoryId;
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (role != null && role.isNotEmpty) params['role'] = role;
    if (size != null && size.isNotEmpty) params['size'] = size;

    final response = await ApiClient.instance.getJson('/products', query: params.isEmpty ? null : params);
    final productsJson = response.data!['data'] as List<dynamic>;
    return productsJson.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
  }

  List<Product> filterProductsLocally({
    String? query,
    String? categoryId,
    String? subCategoryId,
    String? brand,
  }) {
    return CategoryCatalog.filterProducts(
      query: query,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      brand: brand,
    );
  }

  ShopCategory _categoryFromJson(Map<String, dynamic> json) {
    final subs = (json['sub_categories'] as List<dynamic>? ?? [])
        .map(
          (s) => SubCategory(
            id: _asString(s['id']),
            categoryId: _asString(s['category_id']),
            name: s['name'] as String,
            nameEn: s['name_en'] as String?,
            icon: CatalogMeta.subCategoryIcon(_asString(s['id'])),
            imageUrl: s['image_url'] as String?,
          ),
        )
        .toList();

    final id = _asString(json['id']);
    return ShopCategory(
      id: id,
      name: json['name'] as String,
      nameEn: json['name_en'] as String?,
      description: json['description'] as String?,
      icon: CatalogMeta.categoryIcon(id),
      color: CatalogMeta.colorFromHex(json['color_hex'] as String? ?? '#2E3192'),
      imageUrl: json['image_url'] as String?,
      subCategories: subs,
    );
  }

  String _asString(dynamic value) => value?.toString() ?? '';

  void _notifyCatalogChanged() {
    if (Get.isRegistered<AppSearchController>()) {
      Get.find<AppSearchController>().catalogVersion.value++;
    }
    if (_fromApi && Get.isRegistered<CartController>()) {
      Get.find<CartController>().pruneUnavailableItems();
    }
  }
}
