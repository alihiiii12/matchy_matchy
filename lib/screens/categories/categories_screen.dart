import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/models/shop_category.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/category_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(AppStrings.allCategories)),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (embedded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    AppStrings.shopByCategory,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList.separated(
                itemCount: CategoryCatalog.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final category = CategoryCatalog.categories[i];
                  return CategoryCard(
                    category: category,
                    onTap: () => _openCategory(context, category),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(BuildContext context, ShopCategory category) {
    Get.toNamed(AppRoutes.categoryProducts, arguments: category);
  }
}
