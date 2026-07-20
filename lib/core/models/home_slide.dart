import 'package:matchy_matchy/core/data/catalog_meta.dart';

class HomeSlide {
  const HomeSlide({
    required this.id,
    required this.type,
    required this.title,
    required this.sortOrder,
    required this.isActive,
    this.imageUrl,
    this.categoryId,
    this.brandName,
  });

  final String id;
  final String type;
  final String title;
  final String? imageUrl;
  final int sortOrder;
  final bool isActive;
  final String? categoryId;
  final String? brandName;

  bool get isCategory => type == 'category';
  bool get isBrand => type == 'brand';

  String? get resolvedImageUrl => CatalogMeta.resolveImageUrl(imageUrl);

  factory HomeSlide.fromJson(Map<String, dynamic> json) {
    return HomeSlide(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      categoryId: json['category_id'] as String?,
      brandName: json['brand_name'] as String?,
    );
  }
}
