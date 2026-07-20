import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.compact = false,
  });

  final ShopCategory category;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withValues(alpha: 0.2)),
        ),
        child: compact
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CatalogImage(
                    imageUrl: category.displayImageUrl,
                    fallbackIcon: category.icon,
                    fallbackColor: category.color,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.localizedName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CatalogImage(
                    imageUrl: category.displayImageUrl,
                    fallbackIcon: category.icon,
                    fallbackColor: category.color,
                    width: 52,
                    height: 52,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.localizedName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (category.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            category.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: AppColors.textSecondary),
                ],
              ),
      ),
    );
  }
}
