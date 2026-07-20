import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matchy_matchy/core/controllers/admin_home_advertisement_form_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminHomeAdvertisementFormScreen extends GetView<AdminHomeAdvertisementFormController> {
  const AdminHomeAdvertisementFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditing ? AppStrings.editHomeAdvertisement : AppStrings.addHomeAdvertisement),
      ),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel(AppStrings.homeAdvertisementTitle),
            TextFormField(
              controller: controller.titleController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2) return AppStrings.homeAdvertisementTitleRequired;
                return null;
              },
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.homeAdvertisementTitleEn),
            TextFormField(
              controller: controller.titleEnController,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'English title',
              ),
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.homeAdvertisementDescription),
            TextFormField(
              controller: controller.descriptionController,
              textAlign: TextAlign.right,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 5) return AppStrings.homeAdvertisementDescriptionRequired;
                return null;
              },
            ),
            const SizedBox(height: 20),
            _FieldLabel(AppStrings.homeAdvertisementDescriptionEn),
            TextFormField(
              controller: controller.descriptionEnController,
              textDirection: TextDirection.ltr,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                hintText: 'English description',
              ),
            ),
            const SizedBox(height: 20),
            _ImagePicker(
              label: AppStrings.homeAdvertisementImage,
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
                    : (controller.isEditing ? AppStrings.saveChanges : AppStrings.addHomeAdvertisement),
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
