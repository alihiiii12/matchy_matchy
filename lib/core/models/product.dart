import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';

class ProductPieceVariant {
  const ProductPieceVariant({
    required this.id,
    required this.color,
    required this.size,
    required this.price,
    required this.stock,
  });

  final String id;
  final String color;
  final String size;
  final double price;
  final int stock;

  factory ProductPieceVariant.fromJson(Map<String, dynamic> json) {
    return ProductPieceVariant(
      id: json['id']?.toString() ?? '',
      color: json['color'] as String? ?? '',
      size: json['size'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color,
        'size': size,
        'price': price,
        'stock': stock,
      };
}

class ProductPiece {
  const ProductPiece({
    required this.id,
    required this.role,
    this.name,
    this.variants = const [],
  });

  final String id;
  final String role; // father|mother|child
  final String? name;
  final List<ProductPieceVariant> variants;

  factory ProductPiece.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List<dynamic>? ?? [];
    return ProductPiece(
      id: json['id']?.toString() ?? '',
      role: json['role'] as String? ?? '',
      name: json['name'] as String?,
      variants: variantsJson
          .map((e) => ProductPieceVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        'variants': variants.map((v) => v.toJson()).toList(),
      };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.categoryId,
    required this.subCategoryId,
    required this.sellerGovernorateId,
    this.nameEn,
    this.imageUrl,
    this.icon,
    this.rating = 4.5,
    this.isFavorite = false,
    this.unit,
    this.freeDelivery = false,
    this.isFeatured = false,
    this.points = 0,
    this.pieces = const [],
    this.rolePrices = const {},
  });

  final String id;
  final String name;
  final String? nameEn;
  final String brand;
  final double price;
  final String categoryId;
  final String subCategoryId;
  final String sellerGovernorateId;
  final String? imageUrl;
  final IconData? icon;
  final double rating;
  final bool isFavorite;
  final String? unit;
  final bool freeDelivery;
  final bool isFeatured;
  final int points;
  final List<ProductPiece> pieces;

  /// Optional per-role overrides. Missing role → [price].
  final Map<String, double> rolePrices;

  bool get _english {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return LanguageController.instance.isEnglish;
      }
    } catch (_) {}
    return false;
  }

  /// Localized product name (EN when language is English and name_en exists).
  String get localizedName {
    if (_english) {
      final en = nameEn?.trim();
      if (en != null && en.isNotEmpty) return en;
    }
    return name;
  }

  double priceForRole(String? role) {
    if (role == null || role.isEmpty) return price;
    final override = rolePrices[role];
    if (override == null) return price;
    return override;
  }

  static Map<String, double> _parseRolePrices(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, double>{};
    raw.forEach((key, value) {
      if (key == null || value == null || value == '') return;
      final n = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (n != null) out[key.toString()] = n;
    });
    return out;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final categoryId = json['category_id']?.toString() ?? '';
    final subCategoryId = json['sub_category_id']?.toString() ?? '';
    final piecesJson = json['pieces'] as List<dynamic>? ?? [];
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      brand: json['brand'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      sellerGovernorateId: json['seller_governorate_id']?.toString() ?? '',
      imageUrl: CatalogMeta.resolveImageUrl(json['image_url'] as String?),
      icon: CatalogMeta.productIcon(categoryId, subCategoryId),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      unit: json['unit'] as String?,
      freeDelivery: json['free_delivery'] == true || json['free_delivery'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      points: (json['points'] as num?)?.toInt() ?? 0,
      pieces: piecesJson.map((e) => ProductPiece.fromJson(e as Map<String, dynamic>)).toList(),
      rolePrices: _parseRolePrices(json['role_prices']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_en': nameEn,
        'brand': brand,
        'price': price,
        'role_prices': rolePrices,
        'category_id': categoryId,
        'sub_category_id': subCategoryId,
        'seller_governorate_id': sellerGovernorateId,
        'image_url': imageUrl,
        'rating': rating,
        'unit': unit,
        'free_delivery': freeDelivery,
        'is_featured': isFeatured,
        'points': points,
        'pieces': pieces.map((p) => p.toJson()).toList(),
      };

  Product copyWith({
    bool? isFavorite,
    bool? freeDelivery,
    bool? isFeatured,
    int? points,
    List<ProductPiece>? pieces,
    Map<String, double>? rolePrices,
    String? nameEn,
  }) =>
      Product(
        id: id,
        name: name,
        nameEn: nameEn ?? this.nameEn,
        brand: brand,
        price: price,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        sellerGovernorateId: sellerGovernorateId,
        imageUrl: imageUrl,
        icon: icon,
        rating: rating,
        isFavorite: isFavorite ?? this.isFavorite,
        unit: unit,
        freeDelivery: freeDelivery ?? this.freeDelivery,
        isFeatured: isFeatured ?? this.isFeatured,
        points: points ?? this.points,
        pieces: pieces ?? this.pieces,
        rolePrices: rolePrices ?? this.rolePrices,
      );
}
