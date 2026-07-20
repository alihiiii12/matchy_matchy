import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';

class CatalogBrand {
  const CatalogBrand({
    required this.name,
    required this.categoryId,
    this.imageUrl,
  });

  final String name;
  final String categoryId;
  final String? imageUrl;

  String get displayImageUrl {
    final resolved = CatalogMeta.resolveImageUrl(imageUrl);
    if (resolved != null) return resolved;
    return CatalogMeta.categoryImageUrl(categoryId);
  }

  String get bannerImageUrl =>
      displayImageUrl.replaceAll('w=400&h=400', 'w=900&h=400');

  IconData get fallbackIcon => CatalogMeta.categoryIcon(categoryId);

  Color get fallbackColor =>
      CategoryCatalog.categoryById(categoryId)?.color ?? const Color(0xFF2E3192);
}
