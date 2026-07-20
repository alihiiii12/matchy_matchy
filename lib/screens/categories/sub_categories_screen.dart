import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/models/sub_category.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';
import 'package:matchy_matchy/core/widgets/sub_category_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({super.key, required this.category});

  final ShopCategory category;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = Get.find<AppSearchController>().catalogVersion.value;
      final liveCategory = CategoryCatalog.categoryById(category.id) ?? category;
      final subs = liveCategory.subCategories;

      return Scaffold(
        appBar: AppBar(
          title: Text(liveCategory.localizedName),
          backgroundColor: liveCategory.color.withValues(alpha: 0.08),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [liveCategory.color, liveCategory.color.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CatalogImage(
                    imageUrl: liveCategory.displayImageUrl,
                    fallbackIcon: liveCategory.icon,
                    fallbackColor: Colors.white,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveCategory.localizedName,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        if (liveCategory.description != null)
                          Text(
                            liveCategory.description!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(AppStrings.chooseSubcategory, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: subs.isEmpty
                  ? Center(child: Text(AppStrings.noSubCategoriesYet))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: subs.length,
                      itemBuilder: (_, i) {
                        final sub = subs[i];
                        return SubCategoryCard(
                          subCategory: sub,
                          color: liveCategory.color,
                          onTap: () => _openProducts(liveCategory, sub),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }

  void _openProducts(ShopCategory category, SubCategory sub) {
    Get.toNamed(
      AppRoutes.categoryProducts,
      arguments: (category, sub),
    );
  }
}
