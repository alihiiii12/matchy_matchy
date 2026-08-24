import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/featured_products_controller.dart';
import 'package:matchy_matchy/core/controllers/home_free_delivery_controller.dart';
import 'package:matchy_matchy/core/controllers/main_shell_controller.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/brand_logo.dart';
import 'package:matchy_matchy/core/widgets/cart_badge_icon.dart';
import 'package:matchy_matchy/core/widgets/category_card.dart';
import 'package:matchy_matchy/core/widgets/home_advertisement_slider.dart';
import 'package:matchy_matchy/core/widgets/home_category_banner_slider.dart';
import 'package:matchy_matchy/core/widgets/home_quick_actions_bar.dart';
import 'package:matchy_matchy/core/widgets/home_support_button.dart';
import 'package:matchy_matchy/core/widgets/notification_badge_icon.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FeaturedProductsController>()) {
      Get.put(FeaturedProductsController(), permanent: true);
    }
    final featuredController = FeaturedProductsController.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _BrandHero(onProfile: _openProfile)),
          const SliverToBoxAdapter(child: HomeQuickActionsBar()),
          const SliverToBoxAdapter(child: HomeAdvertisementSlider()),
          // مربعات الأقسام + العنوان فوق السلايدر
          Obx(() {
            if (Get.isRegistered<AppSearchController>()) {
              final _ = Get.find<AppSearchController>().catalogVersion.value;
            }
            return SliverToBoxAdapter(child: _buildCategoriesSection(context));
          }),
          SliverToBoxAdapter(child: _buildCategoryBanner()),
          // الأكثر طلباً تحت السلايدر وفوق جميع المنتجات
          Obx(() {
            if (Get.isRegistered<AppSearchController>()) {
              final _ = Get.find<AppSearchController>().catalogVersion.value;
            }
            final featured = _homeFeaturedProducts(featuredController);
            if (featured.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(child: _buildSectionHeader());
          }),
          Obx(() {
            if (Get.isRegistered<AppSearchController>()) {
              final _ = Get.find<AppSearchController>().catalogVersion.value;
            }
            final featured = _homeFeaturedProducts(featuredController);
            if (featured.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = featured[i];
                    return ProductCard(
                      product: product,
                      onTap: () => Get.toNamed(
                        AppRoutes.productDetail,
                        arguments: product,
                      ),
                    );
                  },
                  childCount: featured.length,
                ),
              ),
            );
          }),
          SliverToBoxAdapter(child: _buildAllProductsHeader()),
          Obx(() {
            if (Get.isRegistered<AppSearchController>()) {
              final _ = Get.find<AppSearchController>().catalogVersion.value;
            }
            final all = CategoryCatalog.products;
            if (all.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text('لا توجد منتجات بعد'),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final product = all[i];
                    return ProductCard(
                      product: product,
                      onTap: () => Get.toNamed(
                        AppRoutes.productDetail,
                        arguments: product,
                      ),
                    );
                  },
                  childCount: all.length,
                ),
              ),
            );
          }),
          SliverToBoxAdapter(child: _buildFreeDeliverySection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  void _openProfile() {
    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().setIndex(4);
      return;
    }
    Get.toNamed(AppRoutes.editProfile);
  }

  /// الأكثر طلباً: المعلّمة featured أو كل المنتجات كاحتياط حتى يظهر القسم دائماً.
  static List<Product> _homeFeaturedProducts(FeaturedProductsController ctrl) {
    if (ctrl.products.isNotEmpty) {
      return ctrl.products.toList();
    }
    final catalog = CategoryCatalog.products;
    if (catalog.isEmpty) return const [];
    final marked = catalog.where((p) => p.isFeatured).toList();
    final pool = marked.isNotEmpty ? marked : catalog;
    return pool.take(8).toList();
  }

  Widget _buildCategoryBanner() {
    return HomeCategoryBannerSlider(
      onCategoryTap: (category) => Get.toNamed(AppRoutes.categoryProducts, arguments: category),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final topCategories = CategoryCatalog.categories.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.shopByCategory,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.categories),
                child: Text(
                  AppStrings.seeAll,
                  style: TextStyle(color: AppColors.dustyRose, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: topCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final cat = topCategories[i];
              return SizedBox(
                width: 96,
                child: CategoryCard(
                  category: cat,
                  compact: true,
                  onTap: () => _openCategory(cat),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _openCategory(ShopCategory category) {
    Get.toNamed(AppRoutes.categoryProducts, arguments: category);
  }

  Widget _buildFreeDeliverySection() {
    final freeDeliveryController = Get.put(HomeFreeDeliveryController(), tag: 'home_free_delivery');

    return Obx(() {
      if (Get.isRegistered<AppSearchController>()) {
        final _ = Get.find<AppSearchController>().catalogVersion.value;
      }

      if (freeDeliveryController.loading.value) {
        return const SizedBox.shrink();
      }

      final products = freeDeliveryController.products;
      if (products.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              AppStrings.freeDeliveryProducts,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 232,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) {
                final product = products[index];
                return SizedBox(
                  width: 140,
                  child: ProductCard(
                    product: product,
                    showFreeDeliveryBadge: true,
                    onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: product),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.featuredProducts,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Get.find<AppSearchController>().showAllProducts();
              await Get.toNamed(AppRoutes.searchResult);
            },
            child: Text(
              AppStrings.seeAll,
              style: TextStyle(color: AppColors.dustyRose, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllProductsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.allProducts,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Get.find<AppSearchController>().showAllProducts();
              await Get.toNamed(AppRoutes.searchResult);
            },
            child: Text(
              AppStrings.seeAll,
              style: TextStyle(color: AppColors.dustyRose, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero({required this.onProfile});

  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 12, 12, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfile,
                child: const BrandLogo(size: 52, dark: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.dustyRose,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      AppStrings.appNameEn,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const HomeSupportButton(),
              const CartBadgeIcon(),
              const NotificationBadgeIcon(),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            AppStrings.bannerTitle.replaceAll('\n', ' '),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.shoppingToday,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Get.toNamed(AppRoutes.search),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.homeSearchAction,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
