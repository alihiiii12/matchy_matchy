import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/cart_controller.dart';
import 'package:matchy_matchy/core/data/category_catalog.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }

    if (!controller.canShop) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.myCart)),
        body: const Center(child: Text('السلة متاحة لحسابات الزبائن فقط')),
      );
    }

    return Obx(() {
      final items = controller.cartItems;
      final cart = controller;

      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.myCart)),
        body: items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 72, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      Text(AppStrings.cartEmpty, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(AppStrings.cartEmptyHint, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: controller.continueShopping,
                        child: Text(AppStrings.continueShopping),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final p = item.product;
                        final key = item.cartKey;
                        final cat = CategoryCatalog.categoryById(p.categoryId);
                        final optionsLabel = item.optionsLabel;
                        return Dismissible(
                          key: ValueKey(key),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => cart.removeItem(key, productName: p.localizedName),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            alignment: AlignmentDirectional.centerStart,
                            padding: const EdgeInsetsDirectional.only(start: 20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_outline, color: AppColors.error),
                          ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: (cat?.color ?? AppColors.accent).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(p.icon ?? Icons.shopping_bag, color: cat?.color ?? AppColors.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.localizedName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        if (optionsLabel != null)
                                          Text(
                                            optionsLabel,
                                            style: TextStyle(color: AppColors.accent, fontSize: 12),
                                          ),
                                        Text(
                                          CurrencyFormatter.format(item.unitPrice),
                                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.lineTotal),
                                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => cart.decrement(key),
                                      ),
                                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () => cart.increment(key),
                                      ),
                                      IconButton(
                                        tooltip: AppStrings.removeFromCart,
                                        icon: Icon(Icons.delete_outline, color: AppColors.error),
                                        onPressed: () => cart.removeItem(key, productName: p.localizedName),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${AppStrings.subtotal} (${cart.totalCount} ${AppStrings.items})', style: TextStyle(fontSize: 16)),
                            Text(
                              CurrencyFormatter.format(cart.subtotal),
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: AppStrings.checkout,
                          onPressed: controller.checkout,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
