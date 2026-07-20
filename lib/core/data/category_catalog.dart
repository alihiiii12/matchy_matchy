import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/models/catalog_brand.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';

/// كتالوج احتياطي محلي (مناسبات ماتشي فقط) — المصدر الحقيقي هو API + قاعدة matchy_matchy.
abstract final class CategoryCatalog {
  static const userName = 'أحمد';
  static const userEmail = 'admin@matchymatchy.com';

  static List<ShopCategory> categories = _buildLocalCategories();
  static List<Product> products = _buildLocalProducts();

  static void replaceData({
    required List<ShopCategory> categories,
    required List<Product> products,
  }) {
    CategoryCatalog.categories = categories;
    CategoryCatalog.products = products;
  }

  static List<ShopCategory> _buildLocalCategories() => [
        ShopCategory(
          id: 'occ_eid',
          name: 'اعياد',
          icon: Icons.celebration,
          color: const Color(0xFFC4878F),
          description: 'اطقم عائلية للأعياد',
          subCategories: const [
            SubCategory(id: 'occ_eid_family', categoryId: 'occ_eid', name: 'طقم عائلي للاعياد', icon: Icons.groups),
            SubCategory(id: 'occ_eid_kids', categoryId: 'occ_eid', name: 'اطفال', icon: Icons.child_care),
          ],
        ),
        ShopCategory(
          id: 'occ_wedding',
          name: 'اعراس',
          icon: Icons.favorite,
          color: const Color(0xFFA66B74),
          description: 'اطقم مناسبات واعراس',
          subCategories: const [
            SubCategory(id: 'occ_wedding_family', categoryId: 'occ_wedding', name: 'طقم عائلي', icon: Icons.groups),
            SubCategory(id: 'occ_wedding_formal', categoryId: 'occ_wedding', name: 'رسمي', icon: Icons.checkroom),
          ],
        ),
        ShopCategory(
          id: 'occ_beach',
          name: 'بحر',
          icon: Icons.beach_access,
          color: const Color(0xFFB9D6E8),
          description: 'اطقم صيفية عائلية',
          subCategories: const [
            SubCategory(id: 'occ_beach_family', categoryId: 'occ_beach', name: 'طقم عائلي صيفي', icon: Icons.groups),
            SubCategory(id: 'occ_beach_kids', categoryId: 'occ_beach', name: 'اطفال', icon: Icons.child_care),
          ],
        ),
        ShopCategory(
          id: 'occ_home',
          name: 'منزلي',
          icon: Icons.home,
          color: const Color(0xFF6FAE9E),
          description: 'اطقم منزلية مريحة',
          subCategories: const [
            SubCategory(id: 'occ_home_family', categoryId: 'occ_home', name: 'طقم عائلي', icon: Icons.groups),
            SubCategory(id: 'occ_home_lounge', categoryId: 'occ_home', name: 'استرخاء', icon: Icons.weekend),
          ],
        ),
      ];

  /// لا منتجات وهمية — تظهر فقط بعد التحميل من API / القاعدة.
  static List<Product> _buildLocalProducts() => const [];

  static const notifications = <(String, String, String)>[];

  static const messages = <(String, String, String, bool)>[];

  static const orders = <(String, String, String, String)>[];

  static ShopCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  static SubCategory? subCategoryById(String id) {
    for (final c in categories) {
      for (final s in c.subCategories) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  static List<Product> productsBySubCategory(String subCategoryId) {
    return products.where((p) => p.subCategoryId == subCategoryId).toList();
  }

  static List<Product> productsByCategory(String categoryId) {
    return products.where((p) => p.categoryId == categoryId).toList();
  }

  static Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<Product> freeDeliveryProducts({int limit = 12}) =>
      products.where((product) => product.freeDelivery).take(limit).toList();

  static List<CatalogBrand> distinctBrands() {
    final seen = <String>{};
    final brands = <CatalogBrand>[];

    for (final product in products) {
      final name = product.brand.trim();
      if (name.isEmpty) continue;

      final key = name.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);

      brands.add(
        CatalogBrand(
          name: name,
          categoryId: product.categoryId,
          imageUrl: product.imageUrl,
        ),
      );
    }

    return brands;
  }

  static List<Product> searchProducts(String query) {
    return filterProducts(query: query);
  }

  static List<Product> filterProducts({
    String? query,
    String? categoryId,
    String? subCategoryId,
    String? brand,
  }) {
    var list = products;

    if (categoryId != null && categoryId.isNotEmpty) {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }

    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      list = list.where((p) => p.subCategoryId == subCategoryId).toList();
    }

    if (brand != null && brand.isNotEmpty) {
      list = list.where((p) => p.brand == brand).toList();
    }

    final q = query?.toLowerCase().trim() ?? '';
    if (q.isEmpty) return list;

    return list.where((p) {
      final cat = categoryById(p.categoryId)?.name ?? '';
      final sub = subCategoryById(p.subCategoryId)?.name ?? '';
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          cat.toLowerCase().contains(q) ||
          sub.toLowerCase().contains(q);
    }).toList();
  }
}
