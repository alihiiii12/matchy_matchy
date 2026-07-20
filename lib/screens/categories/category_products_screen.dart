import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({
    super.key,
    required this.category,
    this.subCategory,
  });

  final ShopCategory category;
  final SubCategory? subCategory;

  @override
  Widget build(BuildContext context) {
    final products = subCategory != null
        ? CategoryCatalog.productsBySubCategory(subCategory!.id)
        : CategoryCatalog.productsByCategory(category.id);

    final title = subCategory?.localizedName ?? category.localizedName;
    final subtitle = subCategory != null ? category.localizedName : null;

    return Scaffold(
      appBar: AppBar(
        title: subtitle == null
            ? Text(title)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    subCategory?.icon ?? category.icon,
                    size: 64,
                    color: category.color.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.noProducts, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(AppStrings.comingSoon, style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final product = products[i];
                return ProductCard(
                  product: product,
                  onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: product),
                );
              },
            ),
    );
  }
}
