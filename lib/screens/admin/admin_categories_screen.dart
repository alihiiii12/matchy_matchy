import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_categories_controller.dart';
import 'package:matchy_matchy/core/data/catalog_meta.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class AdminCategoriesScreen extends GetView<AdminCategoriesController> {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.adminCategories),
        actions: [
          IconButton(onPressed: controller.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addCategory),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)));
        }
        if (controller.categories.isEmpty) {
          return Center(child: Text(AppStrings.noCategoriesYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final category = controller.categories[i];
              return _CategoryAdminCard(
                category: category,
                loading: controller.isActionLoading(category['id'] as String),
                canDelete: (category['products_count'] as int? ?? 0) == 0,
                onTap: () => controller.openSubCategories(category),
                onEdit: () => controller.openEditForm(category),
                onDelete: () => controller.deleteCategory(category),
              );
            },
          ),
        );
      }),
    );
  }
}

class _CategoryAdminCard extends StatelessWidget {
  const _CategoryAdminCard({
    required this.category,
    required this.loading,
    required this.canDelete,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> category;
  final bool loading;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = CatalogMeta.colorFromHex(category['color_hex'] as String? ?? '#2E3192');
    final subCount = category['sub_categories_count'] as int? ?? 0;
    final productsCount = category['products_count'] as int? ?? 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CatalogImage(
                    imageUrl: category['image_url'] as String?,
                    fallbackIcon: CatalogMeta.categoryIcon(category['id'] as String),
                    fallbackColor: color,
                    width: 56,
                    height: 56,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'] as String? ?? '—',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$subCount ${AppStrings.subcategories}',
                          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        if (productsCount > 0)
                          Text(
                            '$productsCount ${AppStrings.items}',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_left),
                ],
              ),
              if ((category['description'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                Text(
                  category['description'] as String,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
      ),
    );
  }
}
