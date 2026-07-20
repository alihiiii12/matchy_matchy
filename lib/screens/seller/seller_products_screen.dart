import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/seller_products_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/utils/currency_formatter.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class SellerProductsScreen extends GetView<SellerProductsController> {
  const SellerProductsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  SellerProductsController get controller {
    final tag = 'seller_products_$embedded';
    if (!Get.isRegistered<SellerProductsController>(tag: tag)) {
      Get.put(SellerProductsController(), tag: tag);
    }
    return Get.find<SellerProductsController>(tag: tag);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: embedded
            ? null
            : AppBar(
                title: Text(AppStrings.sellerProducts),
                actions: [
                  IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
                ],
                bottom: _buildTabBar(),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.openCreateForm,
          icon: const Icon(Icons.add),
          label: Text(AppStrings.addProduct),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(controller.error.value!, style: TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: controller.load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (embedded) _EmbeddedHeader(onRefresh: controller.load, tabBar: _buildTabBar()),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.load,
                  child: TabBarView(
                    children: [
                      _ProductsList(
                        controller: controller,
                        items: controller.publishedItems,
                        emptyMessage: AppStrings.noSellerProductsYet,
                        showActions: true,
                      ),
                      _ProductsList(
                        controller: controller,
                        items: controller.pendingItems,
                        emptyMessage: AppStrings.noPendingProducts,
                        showActions: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Obx(
        () => TabBar(
          tabs: [
            Tab(text: '${AppStrings.sellerPublishedProducts} (${controller.publishedItems.length})'),
            Tab(text: '${AppStrings.sellerPendingProducts} (${controller.pendingItems.length})'),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedHeader extends StatelessWidget {
  const _EmbeddedHeader({required this.onRefresh, required this.tabBar});

  final VoidCallback onRefresh;
  final PreferredSizeWidget tabBar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.sellerProducts, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(AppStrings.sellerProductsHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh)),
                ],
              ),
            ),
            tabBar,
          ],
        ),
      ),
    );
  }
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({
    required this.controller,
    required this.items,
    required this.emptyMessage,
    required this.showActions,
  });

  final SellerProductsController controller;
  final List<Map<String, dynamic>> items;
  final String emptyMessage;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 88),
        children: [
          Center(child: Text(emptyMessage, style: TextStyle(color: AppColors.textSecondary))),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (showActions && controller.brandName.value != null && controller.brandName.value!.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.sellerBrandName, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(controller.brandName.value!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...items.map((item) {
          final kind = item['kind'] as String? ?? 'product';
          if (kind == 'submission' || !showActions) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PendingSubmissionCard(item: item),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProductCard(
              product: item,
              loading: controller.isActionLoading(item['id'] as String),
              onEdit: () => controller.openEditForm(item),
              onDelete: () => controller.requestDelete(item),
            ),
          );
        }),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> product;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatalogImage(
                  imageUrl: product['image_url'] as String?,
                  fallbackIcon: Icons.inventory_2_outlined,
                  width: 72,
                  height: 72,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(product['brand'] as String? ?? '—', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format((product['price'] as num?)?.toDouble() ?? 0),
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(AppStrings.publishedProduct, style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppStrings.editProduct),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onDelete,
                    icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    label: Text(AppStrings.deleteProduct, style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingSubmissionCard extends StatelessWidget {
  const _PendingSubmissionCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final isProductPending = item['kind'] == 'product';
    final statusLabel = isProductPending
        ? (item['pending_action'] == 'delete'
            ? AppStrings.pendingDelete
            : item['pending_action'] == 'update'
                ? AppStrings.pendingUpdate
                : AppStrings.pendingReview)
        : (item['status_label'] as String? ?? AppStrings.pendingReview);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CatalogImage(
              imageUrl: item['image_url'] as String?,
              fallbackIcon: Icons.hourglass_top,
              width: 72,
              height: 72,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String? ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  if (!isProductPending)
                    Text(item['action_label'] as String? ?? AppStrings.pendingReview, style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format((item['price'] as num?)?.toDouble() ?? 0),
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(statusLabel, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
