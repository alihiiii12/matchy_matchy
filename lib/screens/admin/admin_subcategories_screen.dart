import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_subcategories_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class AdminSubCategoriesScreen extends GetView<AdminSubCategoriesController> {
  const AdminSubCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Get.back(result: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(controller.categoryName),
          actions: [
            IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: controller.openCreateForm,
          icon: const Icon(Icons.add),
          label: Text(AppStrings.addSubCategory),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.error.value != null) {
            return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
          }
          if (controller.subCategories.isEmpty) {
            return Center(child: Text(AppStrings.noSubCategoriesYet));
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: controller.subCategories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final sub = controller.subCategories[i];
                return _SubCategoryAdminCard(
                  subCategory: sub,
                  categoryColor: CatalogMeta.colorFromHex(controller.category['color_hex'] as String? ?? '#2E3192'),
                  loading: controller.isActionLoading(sub['id'] as String),
                  canDelete: (sub['products_count'] as int? ?? 0) == 0,
                  onEdit: () => controller.openEditForm(sub),
                  onDelete: () => controller.deleteSubCategory(sub),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _SubCategoryAdminCard extends StatelessWidget {
  const _SubCategoryAdminCard({
    required this.subCategory,
    required this.categoryColor,
    required this.loading,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> subCategory;
  final Color categoryColor;
  final bool loading;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final productsCount = subCategory['products_count'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CatalogImage(
                  imageUrl: subCategory['image_url'] as String?,
                  fallbackIcon: CatalogMeta.subCategoryIcon(subCategory['id'] as String),
                  fallbackColor: categoryColor,
                  width: 56,
                  height: 56,
                  circular: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    subCategory['name'] as String? ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ],
            ),
            if (productsCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$productsCount ${AppStrings.items}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(AppStrings.edit),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading || !canDelete ? null : onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: canDelete ? AppColors.error : AppColors.textSecondary,
                      side: BorderSide(color: canDelete ? AppColors.error : AppColors.border),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(AppStrings.delete),
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
