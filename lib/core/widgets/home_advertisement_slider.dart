import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/home_advertisement.dart';
import 'package:matchy_matchy/core/repositories/home_advertisement_repository.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/home_auto_banner_slider.dart';

class HomeAdvertisementSlider extends StatelessWidget {
  const HomeAdvertisementSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = HomeAdvertisementRepository.instance.version.value;
      if (Get.isRegistered<LanguageController>()) {
        LanguageController.instance.code.value;
      }
      final ads = HomeAdvertisementRepository.instance.activeAds;
      if (ads.isEmpty) return const SizedBox.shrink();

      final slides = ads
          .map(
            (ad) => HomeBannerSlideData(
              title: ad.localizedTitle,
              imageUrl: ad.resolvedImageUrl,
              fallbackIcon: Icons.campaign_outlined,
              fallbackColor: AppColors.primary,
              onTap: () => _showDescription(context, ad),
            ),
          )
          .toList();

      return HomeAutoBannerSlider(
        slides: slides,
        kind: HomeBannerSliderKind.advertisement,
      );
    });
  }

  void _showDescription(BuildContext context, HomeAdvertisement ad) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  ad.localizedTitle,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 12),
                Text(
                  ad.localizedDescription.trim().isEmpty
                      ? AppStrings.adDescriptionMissing
                      : ad.localizedDescription,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppStrings.close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
