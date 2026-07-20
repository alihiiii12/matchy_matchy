import 'dart:async';

import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

enum HomeBannerSliderKind {
  plain,
  advertisement,
  mainSlider,
}

class HomeBannerSlideData {
  const HomeBannerSlideData({
    required this.title,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.onTap,
  });

  final String title;
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onTap;
}

class HomeAutoBannerSlider extends StatefulWidget {
  const HomeAutoBannerSlider({
    super.key,
    required this.slides,
    this.kind = HomeBannerSliderKind.plain,
    this.sectionTitle,
    this.sectionIcon,
  });

  final List<HomeBannerSlideData> slides;
  final HomeBannerSliderKind kind;
  final String? sectionTitle;
  final IconData? sectionIcon;

  @override
  State<HomeAutoBannerSlider> createState() => _HomeAutoBannerSliderState();
}

class _HomeAutoBannerSliderState extends State<HomeAutoBannerSlider> {
  static const _slideInterval = Duration(seconds: 4);

  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;

  double get _slideHeight {
    switch (widget.kind) {
      case HomeBannerSliderKind.advertisement:
        // ارتفاع أكبر لعرض صورة الإعلان كاملة بدون قصّ جائر
        return 220;
      case HomeBannerSliderKind.mainSlider:
        return 168;
      case HomeBannerSliderKind.plain:
        return 148;
    }
  }

  Color get _accentColor {
    switch (widget.kind) {
      case HomeBannerSliderKind.advertisement:
        return const Color(0xFFE67E22);
      case HomeBannerSliderKind.mainSlider:
        return AppColors.accent;
      case HomeBannerSliderKind.plain:
        return AppColors.primary;
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_slideInterval, (_) => _goToNextPage());
  }

  void _goToNextPage() {
    if (!mounted || !_pageController.hasClients) return;
    final count = widget.slides.length;
    if (count <= 1) return;

    final next = (_currentPage + 1) % count;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _startAutoSlide();
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) return const SizedBox.shrink();

    if (_currentPage >= slides.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentPage = 0);
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sectionTitle != null) _buildSectionHeader(),
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.sectionTitle != null ? 0 : 12, 20, 0),
          child: Column(
            children: [
              SizedBox(
                height: _slideHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (_, index) => _HomeBannerSlideCard(
                    slide: slides[index],
                    kind: widget.kind,
                    accentColor: _accentColor,
                  ),
                ),
              ),
              if (slides.length > 1) ...[
                const SizedBox(height: 10),
                _buildPageDots(slides.length),
              ],
            ],
          ),
        ),
        if (widget.kind != HomeBannerSliderKind.plain) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final icon = widget.sectionIcon ??
        (widget.kind == HomeBannerSliderKind.advertisement
            ? Icons.campaign_outlined
            : Icons.view_carousel_outlined);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _accentColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.sectionTitle!,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (widget.kind == HomeBannerSliderKind.advertisement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppStrings.homeAdBadge,
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? _accentColor : _accentColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _HomeBannerSlideCard extends StatelessWidget {
  const _HomeBannerSlideCard({
    required this.slide,
    required this.kind,
    required this.accentColor,
  });

  final HomeBannerSlideData slide;
  final HomeBannerSliderKind kind;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = kind == HomeBannerSliderKind.advertisement ? 16.0 : 22.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: slide.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: accentColor.withValues(alpha: kind == HomeBannerSliderKind.plain ? 0 : 0.35),
              width: kind == HomeBannerSliderKind.plain ? 0 : 1.5,
            ),
            boxShadow: kind == HomeBannerSliderKind.plain
                ? null
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: ColoredBox(
                    color: kind == HomeBannerSliderKind.advertisement
                        ? Colors.black.withValues(alpha: 0.04)
                        : Colors.transparent,
                    child: CatalogImage(
                      imageUrl: slide.imageUrl,
                      fallbackIcon: slide.fallbackIcon,
                      fallbackColor: slide.fallbackColor,
                      fit: kind == HomeBannerSliderKind.advertisement
                          ? BoxFit.contain
                          : BoxFit.cover,
                    ),
                  ),
                ),
                if (kind == HomeBannerSliderKind.advertisement) ...[
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      color: accentColor,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppStrings.homeAdBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
                if (kind == HomeBannerSliderKind.mainSlider)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.homeSliderTapHint,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: kind == HomeBannerSliderKind.advertisement ? 0.45 : 0.5),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      slide.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: kind == HomeBannerSliderKind.advertisement ? 18 : 20,
                        height: 1.2,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
