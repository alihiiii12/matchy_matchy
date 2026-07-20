import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';

class HomeAdvertisement {
  const HomeAdvertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.isActive,
    this.titleEn,
    this.descriptionEn,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String? titleEn;
  final String description;
  final String? descriptionEn;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;

  String? get resolvedImageUrl => CatalogMeta.resolveImageUrl(imageUrl);

  bool get _english {
    try {
      if (Get.isRegistered<LanguageController>()) {
        return LanguageController.instance.isEnglish;
      }
    } catch (_) {}
    return false;
  }

  String get localizedTitle {
    if (_english) {
      final en = titleEn?.trim();
      if (en != null && en.isNotEmpty) return en;
    }
    return title;
  }

  String get localizedDescription {
    if (_english) {
      final en = descriptionEn?.trim();
      if (en != null && en.isNotEmpty) return en;
    }
    return description;
  }

  factory HomeAdvertisement.fromJson(Map<String, dynamic> json) {
    return HomeAdvertisement(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      titleEn: json['title_en'] as String?,
      description: json['description'] as String? ?? '',
      descriptionEn: json['description_en'] as String?,
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
