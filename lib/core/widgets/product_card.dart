import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/controllers/language_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/product.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onFavorite,
    this.showFreeDeliveryBadge = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final bool showFreeDeliveryBadge;

  Color get _accent {
    final cat = CategoryCatalog.categoryById(product.categoryId);
    return cat?.color ?? AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.isRegistered<LanguageController>()) {
        LanguageController.instance.code.value;
      }
      if (Get.isRegistered<FavoritesController>()) {
        FavoritesController.instance.favoriteIds.length;
      }
      return _buildCard(context);
    });
  }

  Widget _buildCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _ProductImage(product: product, accent: _accent),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _FavoriteButton(
                  product: product,
                  onFavorite: onFavorite,
                ),
              ),
              if (showFreeDeliveryBadge || product.freeDelivery)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppStrings.freeDelivery,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            product.localizedName,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            product.brand,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(product.price),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.product,
    this.onFavorite,
  });

  final Product product;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FavoritesController>()) {
      return const SizedBox.shrink();
    }

    final favorites = FavoritesController.instance;

    return Obx(() {
      final isFavorite = favorites.isFavorite(product.id);
      return GestureDetector(
        onTap: () {
          if (onFavorite != null) {
            onFavorite!();
            return;
          }
          favorites.toggle(product, context: context);
        },
        behavior: HitTestBehavior.opaque,
        child: CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.inputFill.withValues(alpha: 0.9),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey<bool>(isFavorite),
              size: 16,
              color: isFavorite ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ),
      );
    });
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.accent});

  final Product product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return Image.network(
        product.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _IconPlaceholder(product: product, accent: accent),
      );
    }
    return _IconPlaceholder(product: product, accent: accent);
  }
}

class _IconPlaceholder extends StatelessWidget {
  const _IconPlaceholder({required this.product, required this.accent});

  final Product product;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(product.icon ?? Icons.shopping_bag_outlined, size: 48, color: accent),
      ),
    );
  }
}
