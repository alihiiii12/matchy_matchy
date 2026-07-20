import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisements_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class AdminHomeAdvertisementsScreen extends GetView<AdminHomeAdvertisementsController> {
  const AdminHomeAdvertisementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.adminHomeAdvertisements)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addHomeAdvertisement),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(
            child: Text(controller.error.value!, style: TextStyle(color: AppColors.error)),
          );
        }
        if (controller.ads.isEmpty) {
          return Center(child: Text(AppStrings.noHomeAdvertisementsYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final ad = controller.ads[i];
              return _HomeAdvertisementAdminCard(
                ad: ad,
                loading: controller.isActionLoading(ad['id'] as String),
                onEdit: () => controller.openEditForm(ad),
                onDelete: () => controller.deleteAd(ad),
              );
            },
          ),
        );
      }),
    );
  }
}

class _HomeAdvertisementAdminCard extends StatelessWidget {
  const _HomeAdvertisementAdminCard({
    required this.ad,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> ad;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ad['image_url'] as String?;
    final title = ad['title'] as String? ?? '—';
    final description = ad['description'] as String? ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CatalogImage(
                imageUrl: imageUrl,
                fallbackIcon: Icons.campaign_outlined,
                fallbackColor: AppColors.primary,
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else ...[
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
