import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/favorites_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/widgets/product_card.dart';
import 'package:matchy_matchy/routing/app_routes.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesController.instance;

    return Scaffold(
      appBar: embedded ? null : AppBar(title: Text(AppStrings.myFavorite)),
      body: SafeArea(
        child: Obx(() {
          final items = favorites.favorites;
          if (items.isEmpty) {
            return Center(child: Text(AppStrings.noFavorites));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final product = items[i];
              return ProductCard(
                product: product,
                onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: product),
              );
            },
          );
        }),
      ),
    );
  }
}
