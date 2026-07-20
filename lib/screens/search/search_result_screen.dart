import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/search_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class SearchResultScreen extends StatefulWidget {
  const SearchResultScreen({super.key, this.query});

  final String? query;

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final search = Get.find<AppSearchController>();
      final brand = search.brandFilter.value?.trim();
      if (brand != null && brand.isNotEmpty) return;

      final initialQuery = widget.query ?? Get.arguments as String?;
      if (initialQuery != null && initialQuery.isNotEmpty) {
        search.setQuery(initialQuery);
      } else {
        search.showAllProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppSearchController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final brand = controller.brandFilter.value?.trim();
          if (brand != null && brand.isNotEmpty) {
            return Text('${AppStrings.brandProducts} "$brand"');
          }

          final q = controller.searchQuery.value.trim();
          if (q.isEmpty) return Text(AppStrings.allProducts);
          return Text('${AppStrings.searchResults} "$q"');
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: controller.openFilter,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.results.isEmpty) {
          return Center(child: Text(AppStrings.noResults));
        }

        return GridView.builder(
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
        );
      }),
    );
  }
}
