import 'package:flutter/material.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class SubCategoryCard extends StatelessWidget {
  const SubCategoryCard({
    super.key,
    required this.subCategory,
    required this.color,
    required this.onTap,
    this.fallbackIcon,
  });

  final SubCategory subCategory;
  final Color color;
  final VoidCallback onTap;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final productCount = CategoryCatalog.productsBySubCategory(subCategory.id).length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CatalogImage(
              imageUrl: subCategory.displayImageUrl,
              fallbackIcon: fallbackIcon ?? subCategory.icon ?? Icons.category,
              fallbackColor: color,
              width: 56,
              height: 56,
              circular: true,
            ),
            const SizedBox(height: 12),
            Text(
              subCategory.localizedName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '$productCount ${AppStrings.items}',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

