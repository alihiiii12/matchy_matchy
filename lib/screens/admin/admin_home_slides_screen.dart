import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_home_slides_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';

class AdminHomeSlidesScreen extends StatelessWidget {
  const AdminHomeSlidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.adminHomeSlides),
          bottom: TabBar(
            tabs: [
              Tab(text: AppStrings.categoryHomeSlides),
              Tab(text: AppStrings.brandHomeSlides),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _HomeSlidesTab(slideType: 'category'),
            _HomeSlidesTab(slideType: 'brand'),
          ],
        ),
      ),
    );
  }
}

class _HomeSlidesTab extends GetView<AdminHomeSlidesController> {
  const _HomeSlidesTab({required this.slideType});

  final String slideType;

  @override
  String? get tag => slideType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.openCreateForm,
        icon: const Icon(Icons.add),
        label: Text(AppStrings.addHomeSlide),
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
        if (controller.slides.isEmpty) {
          return Center(child: Text(AppStrings.noHomeSlidesYet));
        }

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: controller.slides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final slide = controller.slides[i];
              return _HomeSlideAdminCard(
                slide: slide,
                isCategory: slideType == 'category',
                loading: controller.isActionLoading(slide['id'] as String),
                onEdit: () => controller.openEditForm(slide),
                onDelete: () => controller.deleteSlide(slide),
              );
            },
          ),
        );
      }),
    );
  }
}

class _HomeSlideAdminCard extends StatelessWidget {
  const _HomeSlideAdminCard({
    required this.slide,
    required this.isCategory,
    required this.loading,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> slide;
  final bool isCategory;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = slide['image_url'] as String?;
    final categoryName = slide['category_name'] as String?;
    final title = isCategory
        ? (categoryName ?? AppStrings.homeSlideCategoryMissing)
        : (slide['title'] as String? ?? '—');

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
                fallbackIcon: isCategory ? Icons.category : Icons.storefront,
                fallbackColor: AppColors.accent,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isCategory && categoryName == null ? AppColors.error : null,
                      ),
                    ),
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