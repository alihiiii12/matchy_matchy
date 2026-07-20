import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/models/home_slide.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/repositories/home_slide_repository.dart';
import 'package:matchy_matchy/core/widgets/home_auto_banner_slider.dart';

/// سلايدر أقسام المناسبات على الرئيسية (اعياد / اعراس / بحر / منزلي).
class HomeCategoryBannerSlider extends StatelessWidget {
  const HomeCategoryBannerSlider({super.key, required this.onCategoryTap});

  final ValueChanged<ShopCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = HomeSlideRepository.instance.version.value;
      if (Get.isRegistered<LanguageController>()) {
        final _ = LanguageController.instance.code.value;
      }
      if (Get.isRegistered<AppSearchController>()) {
        final _ = Get.find<AppSearchController>().catalogVersion.value;
      }
      final slides = _buildSlides();
      return HomeAutoBannerSlider(
        slides: slides,
        kind: HomeBannerSliderKind.mainSlider,
      );
    });
  }

  List<HomeBannerSlideData> _buildSlides() {
    final apiSlides = HomeSlideRepository.instance.categorySlides;
    if (apiSlides.isNotEmpty) {
      final fromApi = apiSlides.map(_slideFromApi).whereType<HomeBannerSlideData>().toList();
      if (fromApi.isNotEmpty) return fromApi;
    }

    // مناسبات ماتشي ماتشي من الكتالوج الحالي
    return CategoryCatalog.categories.map((category) {
      return HomeBannerSlideData(
        title: category.localizedName,
        imageUrl: category.displayImageUrl,
        fallbackIcon: category.icon,
        fallbackColor: category.color,
        onTap: () => onCategoryTap(category),
      );
    }).toList();
  }

  HomeBannerSlideData? _slideFromApi(HomeSlide slide) {
    final categoryId = slide.categoryId;
    if (categoryId == null || categoryId.isEmpty) return null;

    final category = CategoryCatalog.categoryById(categoryId);
    if (category == null) return null;

    final imageUrl = slide.resolvedImageUrl ?? category.displayImageUrl;

    return HomeBannerSlideData(
      title: category.localizedName,
      imageUrl: imageUrl,
      fallbackIcon: category.icon,
      fallbackColor: category.color,
      onTap: () => onCategoryTap(category),
    );
  }
}
