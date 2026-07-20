import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class SearchScreen extends GetView<AppSearchController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller.queryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: Obx(() {
              if (controller.searchQuery.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => controller.setQuery(''),
              );
            }),
          ),
          onSubmitted: controller.submitSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: AppStrings.filter,
            onPressed: () => controller.openFilter(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.hasActiveSearch || controller.isLoading.value) {
          return _LiveResults(controller: controller);
        }
        return _Suggestions(controller: controller);
      }),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.controller});

  final AppSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = controller.catalogVersion.value;
      final popularCategories = CategoryCatalog.categories.take(6).toList();

      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(AppStrings.popularCategories, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...popularCategories.map(
            (cat) => ListTile(
              leading: CatalogImage(
                imageUrl: cat.displayImageUrl,
                fallbackIcon: cat.icon,
                fallbackColor: cat.color,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(cat.localizedName),
              trailing: forwardChevronIcon(context),
              onTap: () => controller.openCategoryProducts(cat),
            ),
          ),
        ],
      );
    });
  }
}

class _LiveResults extends StatelessWidget {
  const _LiveResults({required this.controller});

  final AppSearchController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          final hasFilters = controller.selectedCategoryName != null || controller.selectedSubCategoryName != null;
          if (!hasFilters) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (controller.selectedCategoryName != null)
                  Chip(
                    label: Text(controller.selectedCategoryName!),
                    onDeleted: () => controller.setFilters(
                      categoryId: null,
                      subCategoryId: null,
                    ),
                  ),
                if (controller.selectedSubCategoryName != null)
                  Chip(
                    label: Text(controller.selectedSubCategoryName!),
                    onDeleted: () => controller.setFilters(
                      categoryId: controller.categoryId.value,
                      subCategoryId: null,
                    ),
                  ),
                ActionChip(
                  label: Text(AppStrings.clearFilter),
                  onPressed: controller.clearFilters,
                ),
              ],
            ),
          );
        }),
        Obx(() {
          if (controller.isLoading.value) {
            return const Expanded(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.results.isEmpty) {
            return Expanded(
              child: Center(child: Text(AppStrings.noResults)),
            );
          }

          return Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: controller.results.length,
              itemBuilder: (_, i) {
                final product = controller.results[i];
                return ProductCard(
                  product: product,
                  onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: product),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
