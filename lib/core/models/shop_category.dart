import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/category_i18n.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';

class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.subCategories,
    this.nameEn,
    this.description,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String? nameEn;
  final IconData icon;
  final Color color;
  final List<SubCategory> subCategories;
  final String? description;
  final String? imageUrl;

  bool get _english {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return LanguageController.instance.isEnglish;
      }
    } catch (_) {}
    return false;
  }

  /// Localized display name (AR / EN).
  String get localizedName => CategoryI18n.resolve(
        id: id,
        name: name,
        nameEn: nameEn,
        english: _english,
      );

  String get displayImageUrl =>
      CatalogMeta.resolveImageUrl(imageUrl) ?? CatalogMeta.categoryImageUrl(id);
}
