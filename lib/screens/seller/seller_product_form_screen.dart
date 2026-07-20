import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/seller_product_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/catalog_image.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class SellerProductFormScreen extends GetView<SellerProductFormController> {
  const SellerProductFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editProduct : AppStrings.addProduct),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppStrings.sellerBrandAutoHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.productName),
            TextFormField(
              controller: controller.nameController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المنتج مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.productPrice),
            TextFormField(
              controller: controller.priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.inputFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixText: AppStrings.currencySymbol,
                suffixStyle: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
              ),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n < 0) return 'أدخل سعراً صحيحاً';
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(AppStrings.productUnitFixedHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.productUnit),
            InputDecorator(
              decoration: _inputDecoration(),
              child: Row(
                children: [
                  Text(AppStrings.currencySymbol, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent)),
                  const Spacer(),
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.category),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedCategoryId.value,
                decoration: _inputDecoration(),
                hint: Text(AppStrings.selectCategory),
                items: controller.categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: controller.onCategoryChanged,
                validator: (v) => v == null ? 'اختر القسم' : null,
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.subCategory),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedSubCategoryId.value,
                decoration: _inputDecoration(),
                hint: Text(AppStrings.selectSubCategory),
                items: controller.subCategories
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => controller.selectedSubCategoryId.value = v,
                validator: (v) => v == null ? 'اختر التصنيف الفرعي' : null,
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.governorate),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedGovernorateId.value,
                decoration: _inputDecoration(),
                hint: const Text('اختر المحافظة'),
                items: controller.governorates
                    .map(
                      (g) => DropdownMenuItem<String>(
                        value: g['id'] as String?,
                        child: Text(g['name'] as String? ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (v) => controller.selectedGovernorateId.value = v,
                validator: (v) => v == null ? 'اختر المحافظة' : null,
              ),
            ),
            const SizedBox(height: 20),
            _ImagePicker(
              label: AppStrings.productImage,
              fileName: controller.imageFileName,
              imageFile: controller.imageFile,
              existingImageUrl: controller.existingImageUrl,
              onPick: controller.pickImage,
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.submittingForReview : AppStrings.submitForReview,
                onPressed: controller.submitting.value ? null : controller.submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    return Obx(() {
      final file = imageFile.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file, height: 160, width: double.infinity, fit: BoxFit.cover),
            )
          else if (existingImageUrl != null && existingImageUrl!.isNotEmpty)
            CatalogImage(
              imageUrl: existingImageUrl,
              fallbackIcon: Icons.image_outlined,
              height: 160,
              width: double.infinity,
              borderRadius: BorderRadius.circular(12),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_outlined),
            label: Text(fileName.value ?? label),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        ],
      );
    });
  }
}
