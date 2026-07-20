import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/models/home_slide.dart';
import 'package:matchy_matchy/core/repositories/home_slide_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/home_auto_banner_slider.dart';

class HomeBrandBannerSlider extends StatelessWidget {
  const HomeBrandBannerSlider({super.key, required this.onBrandTap});

  final ValueChanged<String> onBrandTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = HomeSlideRepository.instance.version.value;
      final slides = _buildSlides();
      return HomeAutoBannerSlider(slides: slides);
    });
  }

  List<HomeBannerSlideData> _buildSlides() {
    return HomeSlideRepository.instance.brandSlides
        .map(_slideFromApi)
        .whereType<HomeBannerSlideData>()
        .toList();
  }

  HomeBannerSlideData? _slideFromApi(HomeSlide slide) {
    final title = (slide.brandName ?? slide.title).trim();
    if (title.isEmpty) return null;

    return HomeBannerSlideData(
      title: title,
      imageUrl: slide.resolvedImageUrl,
      fallbackIcon: Icons.storefront,
      fallbackColor: AppColors.accent,
      onTap: () => onBrandTap(title),
    );
  }
}
