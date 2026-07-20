import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matchy_matchy/core/controllers/admin_edit_driver_controller.dart';
import 'package:matchy_matchy/core/l10n/app_strings.dart';
import 'package:matchy_matchy/core/theme/app_colors.dart';
import 'package:matchy_matchy/core/widgets/gradient_button.dart';

class AdminEditDriverScreen extends GetView<AdminEditDriverController> {
  const AdminEditDriverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.editDriver)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _FieldLabel(AppStrings.driverFullName),
            TextFormField(
              controller: controller.nameController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم الكامل مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.vehicleType),
            TextFormField(
              controller: controller.vehicleTypeController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.plateNumber),
            TextFormField(
              controller: controller.plateNumberController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.birthRegion),
            TextFormField(
              controller: controller.birthRegionController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'منطقة التولد مطلوبة' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.birthDate),
            Obx(
              () => InkWell(
                onTap: () => controller.pickBirthDate(context),
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    controller.birthDate.value == null
                        ? 'اختر تاريخ التولد'
                        : DateFormat('yyyy/MM/dd').format(controller.birthDate.value!),
                    style: TextStyle(
                      color: controller.birthDate.value == null ? AppColors.textHint : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.fatherName),
            TextFormField(
              controller: controller.fatherNameController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الأب مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.motherName),
            TextFormField(
              controller: controller.motherNameController,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الأم مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.nationalId),
            TextFormField(
              controller: controller.nationalIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.trim().length < 5) ? 'الرقم الوطني مطلوب' : null,
            ),
            const SizedBox(height: 16),
            _FieldLabel(AppStrings.phone),
            TextFormField(
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]'))],
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.length < 9) return AppStrings.phoneRequired;
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'صور الهوية (اختياري — اتركها فارغة إن لم تُرد التغيير)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _IdPhotoPicker(
              label: AppStrings.idFrontPhoto,
              fileName: controller.idFrontName,
              onPick: () => controller.pickIdPhoto(front: true),
            ),
            const SizedBox(height: 12),
            _IdPhotoPicker(
              label: AppStrings.idBackPhoto,
              fileName: controller.idBackName,
              onPick: () => controller.pickIdPhoto(front: false),
            ),
            const SizedBox(height: 28),
            Obx(
              () => GradientButton(
                label: controller.submitting.value ? AppStrings.savingChanges : AppStrings.saveChanges,
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _IdPhotoPicker extends StatelessWidget {
  const _IdPhotoPicker({required this.label, required this.fileName, required this.onPick});

  final String label;
  final RxnString fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(fileName.value ?? label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
