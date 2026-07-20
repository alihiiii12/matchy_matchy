import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/category_i18n.dart';

class SubCategory {
  const SubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.nameEn,
    this.icon,
    this.imageUrl,
  });

  final String id;
  final String categoryId;
  final String name;
  final String? nameEn;
  final IconData? icon;
  final String? imageUrl;

  bool get _english {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return LanguageController.instance.isEnglish;
      }
    } catch (_) {}
    return false;
  }

  String get localizedName => CategoryI18n.resolve(
        id: id,
        name: name,
        nameEn: nameEn,
        english: _english,
        isSub: true,
      );

  String get displayImageUrl =>
      CatalogMeta.resolveImageUrl(imageUrl) ??
      CatalogMeta.subCategoryImageUrl(id, categoryId: categoryId);
}
