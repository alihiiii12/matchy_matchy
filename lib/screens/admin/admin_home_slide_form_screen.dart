import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_home_slide_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminHomeSlideFormScreen extends GetView<AdminHomeSlideFormController> {
  const AdminHomeSlideFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editHomeSlide : AppStrings.addHomeSlide),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (controller.isCategorySlide) ...[
              _FieldLabel(AppStrings.homeSlideCategory),
              Obx(() {
                if (controller.loadingCategories.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.categories.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppStrings.noCategoriesYet,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final selected = controller.selectedCategoryId.value;
                final items = controller.categories
                    .map(
                      (category) => DropdownMenuItem<String>(
                        value: category['id'] as String?,
                        child: Text(category['name'] as String? ?? '—'),
                      ),
                    )
                    .toList();

                return DropdownButtonFormField<String>(
                  value: items.any((item) => item.value == selected) ? selected : null,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: items,
                  onChanged: (value) => controller.selectedCategoryId.value = value,
                  validator: (_) => controller.selectedCategoryId.value == null
                      ? AppStrings.homeSlideCategoryRequired
                      : null,
                );
              }),
            ] else ...[
              _FieldLabel(AppStrings.homeSlideBrandTitle),
              Obx(() {
                if (controller.loadingBrands.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (controller.sellerBrands.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      AppStrings.noSellerBrandsYet,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                final selected = controller.selectedBrandName.value;
                final items = controller.sellerBrands
                    .map(
                      (brand) => DropdownMenuItem<String>(
                        value: brand,
                        child: Text(brand),
                      ),
                    )
                    .toList();

                return DropdownButtonFormField<String>(
                  value: items.any((item) => item.value == selected) ? selected : null,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: items,
                  onChanged: (value) => controller.selectedBrandName.value = value,
                  validator: (_) => controller.selectedBrandName.value == null
                      ? AppStrings.homeSlideBrandTitleRequired
                      : null,
                );
              }),
            ],
            const SizedBox(height: 20),
            _ImagePicker(
              label: AppStrings.homeSlideImage,
              fileName: controller.imageFileName,
              imageFile: controller.imageFile,
              existingImageUrl: controller.existingImageUrl,
              onPick: controller.pickImage,
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value
                    ? AppStrings.saving
                    : (controller.isEditing ? AppStrings.saveChanges : AppStrings.addHomeSlide),
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.label,
    required this.fileName,
    required this.imageFile,
    required this.existingImageUrl,
    required this.onPick,
  });

  final String label;
  final RxnString fileName;
  final Rxn<File> imageFile;
  final String? existingImageUrl;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Obx(() {
          final file = imageFile.value;
          final previewUrl = file == null ? existingImageUrl : null;

          return Column(
            children: [
              if (file != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(file, height: 140, width: double.infinity, fit: BoxFit.cover),
                )
              else if (previewUrl != null && previewUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(previewUrl, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
              if (file != null || (previewUrl != null && previewUrl.isNotEmpty)) const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.image_outlined),
                label: Text(fileName.value ?? AppStrings.pickImage),
              ),
            ],
          );
        }),
      ],
    );
  }
}
